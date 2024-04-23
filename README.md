# MS Template

- Microservice template.
- Has Postgres database

### Integrations

| Origin            | Target   | Operation                       | HTTP METHOD |
|:------------------|:---------|:--------------------------------|:------------|
| External services | system-x | /api/v2/orderManagement/entityX | GET         |

## Config map

### Telemetry
- **spring.sleuth.otel.exporter.otlp.endpoint**=#ex.http://localhost:4317 sleuth endpoint
- **spring.sleuth.otel.config.trace-id-ratio-based**= #ex:0.0- 0% rate / 1.0 - 100% rate

### DATABASE
- **spring.datasource.url**=#ex. jdbc:postgresql://localhost:5432/catalogdomain
- **spring.datasource.username**=#ex. admin
- **spring.datasource.password**=#ex. admin

### Environment Parametrization
#### External System Endpoints

#### Events
- **event.processing.kafka.address**=#ex. localhost:9092  Kafka Address
- **event.processing.queue.business**=#ex. event-tracing  Topic for business event
- **event.processing.queue.message**=#ex. event-tracing Topic for message event
- **event.processing.queue.application**=#ex. event-tracing Topic for application event
- **event.processing.client.producer.enable**=#ex. false  values true/false parameter to on/of publish event to kafka

#### Logging
- **modules.logging.message.enable** = ex: true
- **modules.logging.message.configuration** = ex: EVENT #listOfValues: CONSOLE,DB,EVENT
- **modules.logging.application.enable** = ex: true
- **modules.logging.application.level** = ex: ERROR #listOfValues: ERROR,DEBUG,WARN
- **modules.logging.application.configuration** = ex:{'*':'CONSOLE,EVENT'} ##listOfValues {'*':{'CONSOLE','DB','FULL','EVENT'}}


### Business Configuration

# Domain Orchestration Template


***Project Structure***:

Note: com.readinessit.microservice should be replaced by the customer domain when working on customer project

``` bash
com
└── readinessit.microservice.template -> root folder should only have application
    ├── adapters -> contains all external system related classes
    |   ├── externalsystem(customer) -> contains classes related to this system, for example generic filling of header structures and error handling and interpretation
    |   └── dto -> all external structures devided by corresponding system
    |       └── crm -> data structure for external system crm
    └── configuration -> implementation specific spring boot configuration on startup
    |   └── security -> spring configuration related to security
    └── ece -> External Communication Engine - engine for all outbound communication (adapters)
    |   ├── action -> All implementations of the action service divided by type
    |   |   ├── courier -> All actions related with external system communication
    |   |   ├── handler -> All actions that will handle a request or response validation/mapping
    |   |   └── mapper -> All actions related to mapping data from/to dtos
    |   ├── condition -> All implementations of the condition service
    |   └── service -> Any service related to a common pipeline implementation, tha can be executed anywhere in the code
    └── domain/functionality -> Specific entity/domain for example an entity or a domain like customer domain
        ├── controller -> Exposed services to the exterior
        ├── entity -> Table entity class  
        ├── persistence -> Repository class
        └── service -> Logic to interact with the entity/domain
```

ECE Guidelines
-
- An ECE interaction is usually defined by a pipeline execution of 3 actions as follows:
    - a mapper ("PRE_RUN_ACTION_ID") that maps the controller request DTO to the external system request DTO structure;
    - a courier ("EXECUTION_ACTION_ID") to make the actual call to the external system;
    - an handler ("POST_RUN_ACTION_ID") to treat the external system response DTO and apply business logic and/or map the information to the execution context or final response;
- A Courier action must only contain the logic for the actual external system call.
  **No mappings or data validation** -> this must be done in a Mapper action;
  **No business logic or response handling** -> this must be done in an Handler action;
- A Courier action external system call must be done via an Adapter;
- A Mapper action should only do request info validation and/or map information from a DTO to the execution context or another DTO;
- An Handler action should handle all business logic and/or the external system response validations and mapping to the execution context;
- A pipeline may be one single execution or be composed of several execution steps in an ordered sequence;
- A pipeline execution may be one handler or sequence up to 3 handlers, a mapper or a sequence up to 3 mappers or an external system call (as explained above);
- Any action may (and should) be used in multiple pipeline executions, wherever the same logic applies;
---


HOW TO DEVELOP AN ECE INTERFACE
-

With the "EXECUTION_CODE" being the "baseService.operation" name defined in a controller: (ex: CustomerRequest.createCustomerRequest)
1) configure the new service in the OC_SERVICES table;
2) configure the pipeline in the correct sequence ("EXECUTION_INDEX"), in the OC_EXECUTION_PIPELINE table.
    - each step is defined by a "PIPELINE_ID" and the "STATUS" (0 or 1) defines if the step is active for execution;
    - if a step must be executed on condition, define the condition class path in "EXECUTION_CONDITION";
3) (if it does not exist already) configure each individual pipeline step ("PIPELINE_ID") in the OC_PIPELINE_DEFINITION table.
    - pipeline executions may (and should) be used in multiple pipelines definitions;
    - an ECE interaction is usually defined by a pipeline execution of 3 actions as follows:
        - a mapper ("PRE_RUN_ACTION_ID") that maps the controller request DTO to the external system request DTO structure;
        - a courier ("EXECUTION_ACTION_ID") to make the actual call to the external system;
        - an handler ("POST_RUN_ACTION_ID") to treat the external system response DTO and apply business logic and/or map the information to the execution context or final response;
    - a pipeline execution may also be just composed of handler(s) action(s) for business logic ("EXECUTION_ACTION_ID");
    - a pipeline execution may also be just composed of mapper(s) action(s) for the pipeline ("EXECUTION_ACTION_ID"); example: a multiple executions pipeline final execution being a mapper to the controller's request final response DTO;
4) (if it does not exist already) configure the class path of each individual pipeline execution action ("EXECUTION_ACTION_ID") in the OC_ACTION_DEFINITION table;
    - actions may (and should) be used in multiple pipelines executions;
5) (if it does not exist already) configure the external system interface information to be used by the adapter for the actual messaging communication in the OC_ADAPTER_DEFINITION;
6) for each adapter interface definition: configure the endpoint of the interface for each environment in the OC_ADAPTER_ENDPOINT table;

---

HOW TO generate liquibase changeset
-
If you are creating or updating an existing table you will need to generate a loquibase changeset, to perform this you will need to do the following:

1) mvn clean
2) mvn compile
3) mvn liquibase:diff

This will generate a new file under resources\db\changelog something like
20220811103406_entity_update.xml

4) Add a more user-friendly message than, entity_update example update_tableName or create_tableName

---

HOW TO UPDATE THE DATABASE
-

***Is it a new Virtual Configuration Table?***

1) create the table data csv file in the resources\db\data folder;
2) generate/create the liquibase changeset in the resources\db\changelog\data folder;
3) include the DB update in the liquibase file: resources\db\master.xml file;

***Is it a new Configuration Table?***
1) create all the necessary JPA entities, repositories, etc;
2) generate/create the liquibase changeset for the table creation in the resources\db\changelog\structure folder;
3) include the DB update in the liquibase file: resources\db\master.xml file;
4) create the table data csv file in the resources\db\data folder;
5) generate/create the liquibase changeset in the resources\db\changelog\data folder;
6) include the DB update in the liquibase file: resources\db\master.xml file under **update data**;

***Is it a structure update to an existing table?***
1) update all the necessary JPA entities, repositories, etc;
2) generate/create the liquibase changeset for the table update in the resources\db\changelog\structure folder;
3) include the DB update in the liquibase file: resources\db\master.xml file under **update structure**;

***Is it a data update to an existing table?***
- just update the respective resources\db\data\*.csv file

---

HOW TO CREATE A NEW CONTROLLER
-
1) Always create a interface class that contains all the relevant operation details
    1) Request Parameters / Headers
    2) Request structure
    3) ExecutionContextDTO
    4) Httpcodes with there corresponding output structure ex: 200 SuccessDto, 400 ErrorDto
2) Implementation class for the created interface, this class will contain the following
    1) Add @RestController annotation to the class
    2) Add @RequestMapping annotation with the path to the api to the class
    3) Add @ControllerECE annotation to each implemented method
    4) The response is always ResponseEntity without the type declaration ex:ResponseEntity<Success> in interface equals to ResponseEntity in implementation, this allows you to responde with error structure on error
---

HOW TO RUN THE UNIT TESTS
- 

Note: **unit tests must be run after every implementation to assure regression**

Either:
- run the test maven command

or

- right-click the test\java folder and choose "Run/Debug All Tests";

A single specific unit test may be run individually by right-clicking the implementing class and choosing "Run/Debug Test";

---

