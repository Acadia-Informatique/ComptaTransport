package com.acadiainfo.comptatransport.fileimport;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(schema = "ComptaTransport", name = "I_ARTICLE_TRANSPORT_ACHETE")
public class ArticleTransportAchete {
	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	@Column(name = "article_path")
	private String articlePath;

	@Column(name = "pricegrid_path")
	private String pricegridPath;

	@Column(name = "description")
	private String description;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getArticlePath() {
		return articlePath;
	}

	public void setArticlePath(String articlePath) {
		this.articlePath = articlePath;
	}

	public String getPricegridPath() {
		return pricegridPath;
	}

	public void setPricegridPath(String pricegridPath) {
		this.pricegridPath = pricegridPath;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}



}

