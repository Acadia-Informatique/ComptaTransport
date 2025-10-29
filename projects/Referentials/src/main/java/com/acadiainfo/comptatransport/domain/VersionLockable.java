package com.acadiainfo.comptatransport.domain;

/**
 * Marks entity which will have a JPA @Version-based optimistic version lock.
 * @see jakarta.persistence.OptimisticLockException
 */
public interface VersionLockable {

	public long get_v_lock();

	public void set_v_lock(long _v_lock);
}
