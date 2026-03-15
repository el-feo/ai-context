# Entity Relationship Diagrams (ERD)

## Entity Attributes

```mermaid
erDiagram
    CUSTOMER {
        int id PK
        string email UK
        string name
        datetime created_at
    }
```

**Format:** `type name constraints`

**Constraints:** `PK` (Primary Key), `FK` (Foreign Key), `UK` (Unique Key), `NN` (Not Null)

**Attribute comments:** Add in quotes after constraints: `varchar email UK "NOT NULL"`

## Relationship Syntax

**Cardinality indicators:**

| Symbol | Meaning |
|--------|---------|
| `\|\|` | Exactly one |
| `\|o` | Zero or one |
| `}{` | One or many |
| `}o` | Zero or many |

**Line types:** `--` (non-identifying), `..` (identifying)

### Common Relationships

```mermaid
erDiagram
    %% One-to-One
    USER ||--|| PROFILE : has

    %% One-to-Many
    CUSTOMER ||--o{ ORDER : places

    %% Many-to-Many (with junction table)
    STUDENT ||--o{ ENROLLMENT : has
    COURSE ||--o{ ENROLLMENT : includes

    %% Optional
    EMPLOYEE |o--o{ DEPARTMENT : manages
```

## Data Types

Standard database types: `int`, `bigint`, `varchar`, `text`, `decimal`, `boolean`, `date`, `datetime`, `timestamp`, `json`, `jsonb`, `uuid`, `blob`

## Common Patterns

### Self-Referencing (Hierarchical)

```mermaid
erDiagram
    CATEGORY ||--o{ CATEGORY : "parent of"
    CATEGORY {
        uuid id PK
        varchar name "NOT NULL"
        uuid parent_id FK "NULLABLE"
    }
```

### Junction Table (Many-to-Many)

```mermaid
erDiagram
    STUDENT ||--o{ ENROLLMENT : has
    COURSE ||--o{ ENROLLMENT : includes
    ENROLLMENT {
        uuid student_id FK PK
        uuid course_id FK PK
        date enrolled_date
    }
```

### Polymorphic Relationship

```mermaid
erDiagram
    COMMENT {
        uuid id PK
        varchar commentable_type "NOT NULL"
        uuid commentable_id "NOT NULL"
        text content
    }
```
