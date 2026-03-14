# Class Diagrams

## Defining Classes

```mermaid
classDiagram
    class BankAccount {
        +String owner
        +Decimal balance
        -String accountNumber
        +deposit(amount)
        +withdraw(amount)
        +getBalance() Decimal
    }
```

**Visibility modifiers:** `+` Public, `-` Private, `#` Protected, `~` Package/Internal

**Member syntax:** `+type attribute` | `+method(params) ReturnType`

## Relationships

| Syntax | Type | Meaning |
|--------|------|---------|
| `A -- B` | Association | Loose relationship, independent |
| `A *-- B` | Composition | Strong ownership, child deleted with parent |
| `A o-- B` | Aggregation | Weak ownership, child exists independently |
| `A <\|-- B` | Inheritance | B extends A |
| `A <.. B` | Dependency | B depends on A (parameter/local) |
| `A <\|.. B` | Realization | B implements interface A |

## Multiplicity

```mermaid
classDiagram
    Customer "1" --> "0..*" Order : places
    Order "1" *-- "1..*" LineItem : contains
```

**Values:** `1`, `0..1`, `0..*` or `*`, `1..*`, `m..n`

## Stereotypes and Abstract

```mermaid
classDiagram
    class IRepository {
        <<interface>>
        +save(entity)
        +findById(id)
    }

    class Shape {
        <<abstract>>
        +draw()* abstract
    }

    class OrderStatus {
        <<enumeration>>
        PENDING
        SHIPPED
    }
```

Other stereotypes: `<<service>>`, `<<dataclass>>`, `<<entity>>`, `<<value object>>`, `<<aggregate root>>`

## Generic Classes

```mermaid
classDiagram
    class List~T~ {
        +add(item: T)
        +get(index: int) T
    }

    List~String~ <-- StringProcessor
```

## Relationship Labels

```mermaid
classDiagram
    Customer --> Order : places
    Driver --> Vehicle : drives
```
