package com.acadiainfo.util.persistence;

import java.lang.reflect.InvocationTargetException;
import java.util.List;
import java.util.Optional;
import java.util.logging.Logger;
import java.util.stream.Stream;

import jakarta.data.Order;
import jakarta.data.page.Page;
import jakarta.data.page.PageRequest;
import jakarta.persistence.EntityManager;

/**
 * Crude CRUD implementation, which will NOT support entity subclasses.
 * BTW, its contract combined with REST API contract tend to make 
 * some duplicate in-database checks unavoidable,
 * so it tends to rely heavily on L1 caching.
 * 
 * TODO JAKARTA DATA - remove when migrating to Jakarta EE 11 (app servers supporting Jakarta Data 1.0 will provided one - better)
 * 
 * @param <T>
 * @param <K>
 */
public abstract class CrudRepositoryImpl<T, K> implements jakarta.data.repository.CrudRepository<T, K> {
	private Logger logger = Logger.getLogger(getClass().getName());

	abstract protected EntityManager getEntityManager();

	abstract protected Class<T> getEntityClass();

	abstract protected K getEntityKey(T t);

	@Override
	public <S extends T> S insert(S t) {
		EntityManager em = this.getEntityManager();

		if (t == null) {
			throw new NullPointerException("Entity in argument can't be null");
		}

		K key = this.getEntityKey(t);
		if (this.findById(key).isPresent()) {
			throw new jakarta.data.exceptions.EntityExistsException("Entity already exist in repository");
		}

		em.persist(t);
		em.flush();
		return t;
	}

	@Override
	public <S extends T> List<S> insertAll(List<S> list) {
		for (S element : list) {
			this.insert(element); // is that too many em.flush() calls ?... check performances
		}
		return list;
	}

	@Override
	public <S extends T> S update(S t) {
		return this.update(t, false);
	}

	/**
	 * Common impl. method for update and patch.
	 * @param <S>
	 * @param t
	 * @param ignoreNulls - defined for REST API Patch, see {@link CrudRepositoryImpl#patchEntity(Object, Object, boolean)}
	 * @return
	 */
	public <S extends T> S update(S t, boolean ignoreNulls) {
		EntityManager em = this.getEntityManager();

		logger.info("update");
		K key = this.getEntityKey(t);
		if (key == null) {
			throw new jakarta.data.exceptions.OptimisticLockingFailureException(
					"Entity key not provided, so it cannot be found");
		}

		T t_in_base = em.find(this.getEntityClass(), key);
		if (t_in_base != null) {
			try {

				logger.info("patchEntity");
					patchEntity(t_in_base, t, ignoreNulls);

				// em.merge(t_in_base);
				// remember, t = em.merge(t); is useless here
				// em.flush();

				t = (S) t_in_base;
				// it *is* unsafe, don't suppress the warning !
				// I'm just trying to match the imposed interface here ;-)

				return t;
			} catch (IllegalAccessException | InvocationTargetException e) {
				throw new RuntimeException("DEV ERROR - Entity class has restricted access", e);
			} catch (ClassCastException e) {
				throw new RuntimeException("DEV ERROR - CrudRepositoryImpl won't honor Jakarta Data's contract", e);
			}
		} else {
			throw new jakarta.data.exceptions.OptimisticLockingFailureException("Entity not found with key=" + key);
		}
	}

	@Override
	public <S extends T> List<S> updateAll(List<S> list) {
		for (S element : list) {
			this.update(element);
		}
		return list;
	}

	@Override
	public void delete(T t) {
		EntityManager em = this.getEntityManager();
		em.remove(t);
		em.flush();
	}

	@Override
	public void deleteAll(List<? extends T> list) {
		for (T element : list) {
			this.delete(element);
		}
	}

	@Override
	public void deleteById(K key) {
		EntityManager em = this.getEntityManager();
		T t = em.find(this.getEntityClass(), key);
		if (t != null) {
			em.remove(t);
			em.flush();
		}
	}

	/**
	 * TODO JAKARTA DATA - relies on the existence of a "findAll" NamedQuery defined at the Entity 
	 */
	@Override
	public Stream<T> findAll() {
		EntityManager em = this.getEntityManager();
		jakarta.persistence.Query query = em.createNamedQuery("findAll"); // all entities are expected to define this
																			// one

		@SuppressWarnings("unchecked")
		Stream<T> resultStream = query.getResultStream();
		return resultStream;
	}

	@Override
	public Page<T> findAll(PageRequest pageReq, Order<T> orderReq) {
		throw new UnsupportedOperationException("Paginated findAll() not supported yet");
	}

	@Override
	public Optional<T> findById(K key) {
		EntityManager em = this.getEntityManager();
		T t = em.find(this.getEntityClass(), key);
		if (t != null) {
			return Optional.of(t);
		} else {
			return Optional.empty();
		}
	}

	@Override
	public <S extends T> S save(S t) {
		this.insert(t);
		EntityManager em = this.getEntityManager();
		t = em.merge(t);
		em.flush();
		return t;
	}

	@Override
	public <S extends T> List<S> saveAll(List<S> list) {
		for (T element : list) {
			this.save(element);
		}
		return list;
	}

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
	protected <S extends T> void patchEntity(S original, S patch, boolean ignoreNulls)
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

//	protected <S extends T> void old_patchEntity(S original, S patch, boolean ignoreNulls)
//			throws IllegalAccessException {
//		logger.info("PATCH ENTITY");
//		Class<T> entityClass = this.getEntityClass();
//		java.lang.reflect.Field[] entityFields = entityClass.getDeclaredFields();
//		for (java.lang.reflect.Field field : entityFields) {
//			int modifiers = field.getModifiers();
//
//			if (field.getName().startsWith("_")) {
//				logger.info(field.getName() + " : JPA injected ignored");
//				continue;
//			}
//			if (field.isSynthetic()
//			  || java.lang.reflect.Modifier.isFinal(modifiers)
//			  || java.lang.reflect.Modifier.isStatic(modifiers)) {
//				logger.info(field.getName() + " : avoided");
//				continue;
//			}
//
//			field.setAccessible(true); // in it was private
//			Object patchValue = field.get(patch);
//			if (!ignoreNulls || patchValue != null) {
//				logger.info(field.getName() + " : copied");
//				field.set(original, patchValue);
//			} else {
//				logger.info(field.getName() + " : null ignored");
//			}
//		}
//
//	}

}
