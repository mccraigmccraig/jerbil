package jerbil.example;

import org.hibernate.annotations.Index;


import javax.persistence.Entity;
import javax.persistence.Column;
import javax.persistence.Id;
import javax.persistence.Table;

/**
 * A basic ejb3 entity for schema validation testing purposes.
 * 
 */
@Entity
// invalid table name: not active record standard
@Table(name = "EntityWithValidationErrors")
public class EntityWithValidationErrors {

    private Long id;
    private String lastName;

		private boolean primary;

    @Id
    public Long getId() {
        return id;
    }

    private void setId(Long id) {
        this.id = id;
    }


		// invalid column name: reserved keyword in mysql5
		@Column(name = "primary" )
		public boolean isPrimary() {
			return primary;
		}

		public void setPrimary(boolean b) {
			primary = b;
		}


		// invalid column name: should be 'last_name'
		@Column(name = "my_freaky_name")
		public String getLastName() {
			return lastName;
		}

		public void setLastName(String n) {
			this.lastName = n;
		}

}
