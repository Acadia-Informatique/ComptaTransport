package com.acadiainfo.util.persistence;

import java.lang.reflect.InvocationTargetException;
import java.util.List;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.domain.VersionLockable;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Parameter;
import jakarta.persistence.Query;

/**
 * Crude CRUD implementation, which will NOT support entity subclasses.
 * Inspired by Jakarta Data (in fact, started as a handwritten impl.).
 *  
 * @param <T> - Entity type
 * @param <K> - Key type
 */
public abstract class CrudRepositoryImpl<T, K> {
	private static final Logger logger = Logger.getLogger(CrudRepositoryImpl.class.getName());

	/**
	 * (Describe the Entity class involved) 
	 * @return explicitly the Entity class
	 */
	abstract protected Class<T> getEntityClass();

	/**
	 * (Describe the Entity class involved)
	 * @param t
	 * @return the extracted key value for this entity
	 */
	abstract protected K getEntityKey(T t);

	/* JPA EntityManager to be used */
	private EntityManager em;

	/**
	 * Protected constructor to inject the EntityManager. 
	 * @param em - Better not try to reuse this JPA EntityManager beyond the scope of the surrounding injection (one EJB call).
	 */
	protected CrudRepositoryImpl(EntityManager em) {
		this.em = em;
	}

	/**
	 * Access the injected EntityManager, especially in subclasses.
	 * @return
	 */
	protected EntityManager getEntityManager() {
		return em;
	}

	/**
	 * Insert one entity.
	 *
	 * @param t - Entity to be persisted
	 * @return the "JPA attached" version of arg.
	 */
	public T insert(T t) {
		EntityManager em = this.getEntityManager();

		if (t == null) {
			throw new IllegalArgumentException(this.getEntityClass().getSimpleName() + " in argument can't be null");
		}
		try {			
			em.persist(t);
			em.flush();
			// em.refresh(t); // for database generated fields
			return t;
		} catch (jakarta.persistence.PersistenceException exc) {
			throw explicitPersistenceException(t, exc);
		}
	}


	/**
	 * Update one existing entity from an external "data bag" (must have key though) 
	 * Common impl. method for update and patch.
	 * @param t "Data bag" entity to be updated, must have key, but won't get attached. 
	 * @param ignoreNulls - defined for REST API Patch, see {@link CrudRepositoryImpl#patchEntity(Object, Object, boolean)}
	 * @return the "JPA attached" version of arg.
	 * @throws some jakarta.persistence.PersistenceException and subclasses (for not existing, version conflicts, etc.)
	 */
	public T update(T t, boolean ignoreNulls) {
		EntityManager em = this.getEntityManager();

		K key = this.getEntityKey(t);
		if (key == null) {
			throw new IllegalArgumentException(this.getEntityClass().getSimpleName() + " must have a non-null key.");
		}

		T t_in_base = em.find(this.getEntityClass(), key);

		if (t_in_base != null) {
			try {
				patchBean(t_in_base, t, ignoreNulls);

				em.flush();

				// em.clear();
				em.refresh(t_in_base);

				return t_in_base;
			} catch (IllegalAccessException | InvocationTargetException e) {
				throw new RuntimeException("DEV ERROR - Entity class has restricted access", e);
			} catch (jakarta.persistence.OptimisticLockException exc) {
				// Rethrow to make it less intimidating
				throw new jakarta.persistence.OptimisticLockException(this.getEntityClass().getSimpleName()
						+ " cannot be updated because it has changed since last read", exc);
			} catch (jakarta.persistence.PersistenceException exc) {
				throw explicitPersistenceException(t, exc);
			}
		} else {
			throw new jakarta.persistence.EntityNotFoundException(this.getEntityClass().getSimpleName()
					+ " may be deleted since last read, not found with key=" + key);
		}
	}


	/**
	 * Delete one existing entity by key.
	 * A less "brutal" version of {@link #deleteById(Object)}: technical versions are compared when available.
	 * @param t - Entity to be removed.
	 * @throws jakarta.persistence.EntityNotFoundException when not found
	 * @throws jakarta.persistence.OptimisticLockException for version conflicts
	 */
	public void delete(final T t) {
		if (t == null) {
			throw new IllegalArgumentException("Error deleting null " + this.getEntityClass().getSimpleName());
		}

		EntityManager em = this.getEntityManager();
		T t_in_base = this.findById(this.getEntityKey(t));
		if (t_in_base == null) {
			throw new jakarta.persistence.EntityNotFoundException(
					this.getEntityClass().getSimpleName() + " with same key doesn't exist anymore in database");
		} else if (t instanceof VersionLockable) {			 
			long lock_in_base = ((VersionLockable) t_in_base).get_v_lock();
			long lock_in_arg = ((VersionLockable) t).get_v_lock();
			if (lock_in_arg < lock_in_base) {
				throw new jakarta.persistence.OptimisticLockException("Incoming version is out-dated.");
			} else if (lock_in_arg > lock_in_base){
				throw new jakarta.persistence.OptimisticLockException(
						"Incoming version higher than existing one (forged ?).");
			}
		}
		em.remove(t_in_base);
		em.flush();
	}


	/**
	 * Delete one existing entity by key.
	 * @param key - identifies the entity to be removed
	 * @throws jakarta.persistence.EntityNotFoundException when not found
	 */
	public void deleteById(K key) {
		if (key == null) {
			throw new IllegalArgumentException(
			  "Error deleting " + this.getEntityClass().getSimpleName() + " from null key");
		}

		EntityManager em = this.getEntityManager();
		T t = em.find(this.getEntityClass(), key);
		if (t != null) {
			em.remove(t);
			em.flush();
		} else {
			throw new jakarta.persistence.EntityNotFoundException(
			  this.getEntityClass().getSimpleName() + " not found with key = " + key);
		}
	}

	/**
	 * Retrieve all entities in repository, which can use up a lot of resources for big ones. 
	 * Important : Relies on the existence of a "[Entity].findAll" NamedQuery, usually defined at the Entity
	 * @return found entities 
	 */
	public Stream<T> findAll() {
		EntityManager em = this.getEntityManager();
		Query query = em.createNamedQuery(this.getEntityClass().getSimpleName() + ".findAll");

		@SuppressWarnings("unchecked")
		Stream<T> resultStream = query.getResultStream();
		return resultStream;
	}


	/**
	 * Get one existing by id, or test its existence.
	 * @param key
	 * @return found entity or null.
	 */
	public T findById(K key) {
		if (key == null) {
			throw new IllegalArgumentException("Entity cannot be found from a null key");
		}
		EntityManager em = this.getEntityManager();
		return em.find(this.getEntityClass(), key);
	}

	/**
	 * Short-hand for {@link #findById(Object)}.
	 * @param entity
	 * @return found entity or null.
	 */
	public T find(T entity) {
		if (entity == null) {
			throw new IllegalArgumentException("Entity to find cannot be null");
		}
		return this.findById(this.getEntityKey(entity));
	}

	/**
	 * Save back one JPA entity (from database ideally, not deserialized).
	 * @param t - Entity to save
	 * @return up-to-date
	 */
	public T save(T t) {
		EntityManager em = this.getEntityManager();
		t = em.merge(t);
		em.flush();
		return t;
	}

	/**
	 * Batch version of {@link #save(Object)}.
	 * @param list - Entities to save
	 * @return new ArrayList of merged entities.
	 */
	public List<T> saveAll(List<T> list) {
		List<T> newList = new java.util.ArrayList<T>(list.size());
		EntityManager em = this.getEntityManager();
		for (T t : list) {
			newList.add(em.merge(t));
		}
		em.flush();
		return newList;
	}

	/*-------- instance-level utils ------- */

	/**
	 * Very shallow reflective bean patching.
	 * Could have used {@link https://commons.apache.org/proper/commons-beanutils/} instead..
	 * @param <S>
	 * @param original - the bean to be modified
	 * @param patch - the new data
	 * @param ignoreNulls - if true, only non-null fields are considered relevant
	 * @throws IllegalAccessException when the copy fails 
	 * @throws InvocationTargetException  when the copy fails
	 */
	protected void patchBean(T original, T patch, boolean ignoreNulls)
			throws IllegalAccessException, InvocationTargetException {
		Class<T> entityClass = this.getEntityClass();
		java.lang.reflect.Method[] entityMethods = entityClass.getDeclaredMethods();
		for (java.lang.reflect.Method setterC : entityMethods) {					
			String propertyName;
			Class<?> propertyType; 
						
			if (setterC.getName().startsWith("set")
			  && !setterC.isSynthetic() && !setterC.isVarArgs()
			  && !java.lang.reflect.Modifier.isStatic(setterC.getModifiers())
			  && java.lang.reflect.Modifier.isPublic(setterC.getModifiers())
			  && setterC.getParameterCount() == 1
			  && setterC.getReturnType().equals(Void.TYPE)) {
				propertyName = setterC.getName().substring("set".length());
				propertyType = setterC.getParameters()[0].getType();
			} else {
				continue;
			}

			String getterName;
			if (propertyType == Boolean.class ||  propertyType == Boolean.TYPE) {
				getterName = "is" + propertyName;
			} else {
				getterName = "get" + propertyName;
			}

			for (java.lang.reflect.Method getterC : entityMethods) {
				if (getterName.equals(getterC.getName())
						&& !getterC.isSynthetic() && !getterC.isVarArgs()
						&& !java.lang.reflect.Modifier.isStatic(getterC.getModifiers())
						&& java.lang.reflect.Modifier.isPublic(getterC.getModifiers())
						&& getterC.getParameterCount() == 0 && getterC.getReturnType().equals(propertyType)) {
					logger.finest("getter/setter couple found for :" + propertyName);
					Object value = getterC.invoke(patch);
					setterC.invoke(original, value);
				}
			}
		}
	}

	/** 
	 * Look into a PersistenceException for a SQL-based cause, as a safety net for insufficient checking.
	 * The messages at repository level are meant for debugging, and are not properly localized. 
	 * 
	 * @param entity to which it happened. Can be null if it doesn't apply.
	 * @param exc
	 * @return a "human readable" version of the exc argument (may be another PersistenceException)
	 */
	protected jakarta.persistence.PersistenceException explicitPersistenceException(T entity,
			jakarta.persistence.PersistenceException exc) {
		// Lazy check for duplicate, since it is costly
		// (and so unlikely, should only happen for non-generated PK)
		Throwable cause = com.acadiainfo.util.ExceptionUtils.unwrapToSqlBasedException(exc);
		if (cause instanceof java.sql.SQLIntegrityConstraintViolationException) {
			if (entity != null && this.getEntityKey(entity) != null && isDuplicatePKMsg(cause.getMessage())) {
				K key = this.getEntityKey(entity);
				T duplicate = this.findById(key);
				if (duplicate != null) {
					return new jakarta.persistence.EntityExistsException(
							this.getEntityClass().getSimpleName() + " with same key already exists : " + key);
				}
			} else {
				return new com.acadiainfo.util.DataIntegrityViolationException(cause);
			}
	 // } else if ... TODO add analysis for other common java.sql.* exceptions			
		} else {
			// simplify the message and cause chain
			return new jakarta.persistence.PersistenceException(cause.getMessage());
		}

		// if nothing applies, return original
		return exc;
	}

	/**
	 * Tells if the db exception is a PK violation message, based on my own database settings,
	 * and my own PK constraint naming habits. 
	 * TODO document current database settings (MySQL + UTC timezone + US-EN locale).
	 * 
	 * @param message - Some java.sql.SQLIntegrityConstraintViolationException.getMessage()
	 * @return true if the message "looks ok" (couldn't do better for years ;-)  
	 */
	private boolean isDuplicatePKMsg(String message) {
		return (message != null && message.startsWith("Duplicate entry") && message.endsWith(".PRIMARY'"));
	}
}
