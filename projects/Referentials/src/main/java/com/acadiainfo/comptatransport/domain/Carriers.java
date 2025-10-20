package com.acadiainfo.comptatransport.domain;


import jakarta.data.repository.CrudRepository;

import jakarta.data.repository.Repository;

@Repository
public interface Carriers extends CrudRepository<Carrier, String> {

}
