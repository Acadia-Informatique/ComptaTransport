package com.acadiainfo.comptatransport;

import jakarta.json.bind.annotation.JsonbProperty;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Toto {
	@Id @GeneratedValue(strategy = GenerationType.IDENTITY)
	private long id;
	
	
	@JsonbProperty
	@Column(length=100)
	private String name;
	
	
	public String sayHello() {
		return "Hi "+ this.name + "#" + this.id; 
	}


	public void setName(String name) {
		this.name = name;		
	}

	

}
