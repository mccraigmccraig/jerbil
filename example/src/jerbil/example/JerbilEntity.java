package jerbil.example;

import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

/**
 * A basic ejb3 entity for testing purposes.
 */
@Entity
@Table(name = "jerbil_entities")
public class JerbilEntity {

    private Long id;
    private String name;

    @Id
    public Long getId() {
        return id;
    }

    private void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
