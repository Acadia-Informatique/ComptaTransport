package bidouilletesting;

import java.util.SortedSet;
import java.util.TreeSet;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Toto {
	@Id @GeneratedValue(strategy = GenerationType.IDENTITY)
	private long id;
	

	@Column(length=100)
	private String name;
	
	
	@Column
	@Convert(converter = com.acadiainfo.util.persistence.StringSetConverter.class)
	private SortedSet<String> adjectives = new TreeSet<String>();

	
	// @ManyToMany(fetch = FetchType.EAGER)
	
	public String sayHello() {
		return "Hi " + this.name + "#" + this.id + " : " + this.adjectives.getClass().getCanonicalName();
	}


	public void setName(String name) {
		this.name = name;		
	}

	public void addAdjective(String adj) {
		this.adjectives.add(adj);
	}

	public long getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public SortedSet<String> getAdjectives() {
		return adjectives;
	}
	


	

}
