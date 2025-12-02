package com.acadiainfo.comptatransport.domain;

/**
 * Marks entity which will have a JPA @Version-based optimistic version lock.
 * @see jakarta.persistence.OptimisticLockException
 */
public interface VersionLockable {

	public Long get_v_lock();

	public void set_v_lock(Long _v_lock);
}
