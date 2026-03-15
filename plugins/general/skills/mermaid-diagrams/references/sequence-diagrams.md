# Sequence Diagrams

## Participants and Actors

```mermaid
sequenceDiagram
    actor User
    participant Frontend
    participant API
    participant Database
```

- `participant` — system components
- `actor` — external entities (users, external systems)

## Message Types

| Syntax | Meaning |
|--------|---------|
| `->>` | Solid arrow (synchronous request) |
| `-->>` | Dotted arrow (response/return) |
| `-)` | Solid open arrow (async) |
| `--)` | Dotted open arrow (async response) |
| `-x` | Cross/delete |

## Activations

`+` after arrow activates, `-` before arrow deactivates:

```mermaid
sequenceDiagram
    Client->>+Server: Request
    Server->>+Database: Query
    Database-->>-Server: Data
    Server-->>-Client: Response
```

## Control Flow Blocks

### alt/else (Conditional)

```mermaid
sequenceDiagram
    API->>Database: Query user
    alt Valid credentials
        API-->>User: 200 OK
    else Invalid credentials
        API-->>User: 401 Unauthorized
    end
```

### opt (Optional)

```mermaid
sequenceDiagram
    opt Payment successful
        API->>EmailService: Send confirmation
    end
```

### par (Parallel)

```mermaid
sequenceDiagram
    par Send email
        Service->>EmailService: Send confirmation
    and Update inventory
        Service->>InventoryService: Reduce stock
    end
```

### loop

```mermaid
sequenceDiagram
    loop For each item
        Server->>Database: Process item
        Database-->>Server: Result
    end
```

### break (Early Exit)

```mermaid
sequenceDiagram
    break Input invalid
        API-->>User: 400 Bad Request
    end
```

## Notes

```mermaid
sequenceDiagram
    Note over API: Validates JWT token
    Note over Frontend,API: HTTPS encrypted
    Note right of System: Logs to database
```

## Sequence Numbers

```mermaid
sequenceDiagram
    autonumber
    User->>Frontend: Login
    Frontend->>API: Authenticate
```

## Links

```mermaid
sequenceDiagram
    participant A as Service A
    link A: Dashboard @ https://dashboard.example.com
```
