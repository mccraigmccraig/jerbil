package jerbil.example;

import org.hibernate.annotations.Index;


import javax.persistence.Entity;
import javax.persistence.Column;
import javax.persistence.Id;
import javax.persistence.Table;

/**
 * A basic ejb3 entity for testing purposes.
 */
@Entity
@Table(name = "jerbil_entities")
public class JerbilEntity {

    private Long id;
    private String name, lastName;

		private boolean primary;

    @Id
    public Long getId() {
        return id;
    }

    private void setId(Long id) {
        this.id = id;
    }

    @Index( name = "name_idx" )
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

		// not activerecord conformant, but reserved
		@Column(name = "is_primary" )
		public boolean isPrimary() {
			return primary;
		}

		public void setPrimary(boolean b) {
			primary = b;
		}

		@Column(name = "last_name")
		public String getLastName() {
			return lastName;
		}

		public void setLastName(String n) {
			this.lastName = n;
		}
}
