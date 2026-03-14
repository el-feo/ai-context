# C4 Model Diagrams

The C4 model visualizes software architecture at four levels: Context, Containers, Components, and Code.

## C4 Context Diagram

Shows your system, its users, and external systems.

### Elements

**People:**
- `Person(id, "Name", "Description")`
- `Person_Ext(id, "Name", "Description")` — external

**Systems:**
- `System(id, "Name", "Description")` — internal
- `System_Ext(id, "Name", "Description")` — external
- `SystemDb(id, "Name", "Description")` — database system
- `SystemQueue(id, "Name", "Description")` — message queue
- Add `_Ext` suffix for external variants of Db/Queue

**Relationships:**
- `Rel(from, to, "Label")`
- `Rel(from, to, "Label", "Technology")`
- `BiRel(a, b, "Label")` — bidirectional

```mermaid
C4Context
    title System Context for Banking System

    Person(customer, "Customer", "A banking customer")
    System(banking, "Banking System", "Manages accounts")
    System_Ext(email, "Email System", "Sends emails")

    Rel(customer, banking, "Uses")
    Rel(banking, email, "Sends emails via")
```

## C4 Container Diagram

Zooms into a system to show applications, databases, and services.

### Elements

- `Container(id, "Name", "Technology", "Description")`
- `ContainerDb(id, "Name", "Technology", "Description")`
- `ContainerQueue(id, "Name", "Technology", "Description")`
- Add `_Ext` for external variants

### Boundaries

```mermaid
C4Container
    title Container Diagram for Banking System

    Person(customer, "Customer")

    Container_Boundary(banking, "Banking System") {
        Container(web, "Web App", "React", "Delivers UI")
        Container(api, "API", "Node.js", "Banking API")
        ContainerDb(db, "Database", "PostgreSQL", "Account data")
    }

    Rel(customer, web, "Uses", "HTTPS")
    Rel(web, api, "Calls", "HTTPS/JSON")
    Rel(api, db, "Reads/writes", "SQL")
```

## C4 Component Diagram

Zooms into a container to show internal components.

```mermaid
C4Component
    title Component Diagram for API

    Container(web, "Web App", "React")
    ContainerDb(db, "Database", "PostgreSQL")

    Container_Boundary(api, "API Application") {
        Component(controller, "Controller", "Express Router", "Handles HTTP")
        Component(service, "Business Logic", "Service Layer", "Core logic")
        Component(repository, "Data Access", "Repository", "DB operations")
    }

    Rel(web, controller, "Requests", "HTTPS")
    Rel(controller, service, "Uses")
    Rel(service, repository, "Uses")
    Rel(repository, db, "Reads/writes", "SQL")
```

## Layout Hints

- `UpdateRelStyle(from, to, $offsetX="50", $offsetY="-30")` — adjust label positions
- Use `Container_Boundary` to group related containers
- Level 4 (Code) uses regular `classDiagram` syntax
