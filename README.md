# Flextrine

Flextrine is a powerful solution for creating Flex/PHP rich internet applications currently providing a persistence API and remote method invokation. The ultimate goal of Flextrine is to provide a similar feature set as LiveCycle Data Services for the Flex/PHP developer.

# Requirements
- Flex 3, Flex 4
- PHP 5.3+
- MySQL, PostgreSQL, SQLite, Oracle (more coming)

# Features
## Object persistence
Flextrine gives you a very powerful asynchronous client-server ORM (object-relational mapper) directly within Flex itself with full support for associations, relations, complex queries, lazy loading and inheritance.

## Data binding
Flextrine is built from the ground up to respect Flex data-binding, and you can bind entities and collections to Flex components and trust that they will automatically update whenever data is reloaded or resynchronized.

## One row, one object
Flextrine puts a lot of work into ensuring that you only ever have a single instance of an AS3 object for each row in the database. This means that you can persist, update and remove objects knowing that all objects in your application will respect the changes.

## Multi-client syncronisation
Flextrine has been designed from the ground up to support real-time multi-client updates through Remote Shared Objects using a media server such as Flash Media Server, Wowza or Red5.  This will eventually be used provide features similar to LiveCycle Data Service's real-time DataSource component.

# How does it work?
Flextrine is actually a Flex frontend onto Doctrine 2, a powerful ORM system for PHP.  Doctrine performs the persistence heavy-lifting, and Flextrine manages the communications, local object caches, instance management and client side lazy/eager loading strategies.

# This sounds complicated! Why do I care?

Well, its like this. The following code creates a Customer and saves it to the database:

```as3
var myCustomer:Customer = new Customer();
myCustomer.name = "Joe Bloggs";

EntityManager.persist(myCustomer);
EntityManager.flush();
```

Well... that was surprisingly short. Surely there is a load of PHP on the other side to make this work?

```php
<?php

/**
 * @Entity
 */
class Customer {

    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
        
    /** @Column(length=100, type="string") */
    public $name;

}
```