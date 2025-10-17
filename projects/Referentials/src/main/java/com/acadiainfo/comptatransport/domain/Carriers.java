package com.acadiainfo.comptatransport.domain;

import jakarta.data.repository.CrudRepository;
import jakarta.data.repository.OrderBy;
import jakarta.data.repository.Repository;

@Repository
//@jakarta.enterprise.inject.Model
public interface Carriers extends CrudRepository<Carrier, Long> {

	@OrderBy("price")
	public java.util.List<Carrier> findByNameLike(String namePattern);

	// java.util.List<Car> findByMakeAndModel(String make, String model, Sort<?>...
	// sorts);
}
