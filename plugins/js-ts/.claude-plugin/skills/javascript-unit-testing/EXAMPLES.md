# JavaScript Unit Testing Examples

Comprehensive collection of real-world testing examples and patterns.

## Table of Contents

- [Basic Test Examples](#basic-test-examples)
- [Testing Different Exit Points](#testing-different-exit-points)
- [Dependency Injection Examples](#dependency-injection-examples)
- [Async Testing Examples](#async-testing-examples)
- [Mock and Stub Examples](#mock-and-stub-examples)
- [Test Refactoring Examples](#test-refactoring-examples)
- [Common Scenarios](#common-scenarios)

## Basic Test Examples

### Simple Function Testing

```javascript
// sum.js
const sum = (numbers) => {
  const [a, b] = numbers.split(',');
  return parseInt(a) + parseInt(b);
};

module.exports = { sum };

// sum.test.js
const { sum } = require('./sum');

describe('sum', () => {
  test('with two positive numbers, returns their sum', () => {
    const result = sum('1,2');
    expect(result).toBe(3);
  });

  test('with negative numbers, returns correct result', () => {
    const result = sum('-5,3');
    expect(result).toBe(-2);
  });

  test('with zero, returns other number', () => {
    const result = sum('0,7');
    expect(result).toBe(7);
  });
});
```

### Password Verifier Example

```javascript
// password-verifier.js
class PasswordVerifier {
  constructor(rules = []) {
    this.rules = rules;
  }

  verify(input) {
    if (this.rules.length === 0) {
      throw new Error('There are no rules configured');
    }

    const errors = [];
    for (const rule of this.rules) {
      const result = rule(input);
      if (!result.passed) {
        errors.push(result.reason);
      }
    }

    return {
      passed: errors.length === 0,
      errors
    };
  }
}

// Rules
const oneUpperCaseRule = (input) => {
  return {
    passed: /[A-Z]/.test(input),
    reason: 'Must have at least one uppercase letter'
  };
};

const oneLowerCaseRule = (input) => {
  return {
    passed: /[a-z]/.test(input),
    reason: 'Must have at least one lowercase letter'
  };
};

const oneNumberRule = (input) => {
  return {
    passed: /[0-9]/.test(input),
    reason: 'Must have at least one number'
  };
};

module.exports = {
  PasswordVerifier,
  oneUpperCaseRule,
  oneLowerCaseRule,
  oneNumberRule
};

// password-verifier.test.js
const {
  PasswordVerifier,
  oneUpperCaseRule,
  oneLowerCaseRule,
  oneNumberRule
} = require('./password-verifier');

describe('PasswordVerifier', () => {
  const makeVerifier = (rules = []) => {
    return new PasswordVerifier(rules);
  };

  describe('verify', () => {
    test('with no rules configured, throws exception', () => {
      const verifier = makeVerifier();

      expect(() => verifier.verify('anything'))
        .toThrow(/no rules configured/);
    });

    test('with passing rule, returns success', () => {
      const passingRule = () => ({ passed: true });
      const verifier = makeVerifier([passingRule]);

      const result = verifier.verify('input');

      expect(result.passed).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    test('with failing rule, returns failure with reason', () => {
      const failingRule = () => ({
        passed: false,
        reason: 'too short'
      });
      const verifier = makeVerifier([failingRule]);

      const result = verifier.verify('abc');

      expect(result.passed).toBe(false);
      expect(result.errors).toContain('too short');
    });

    test('with multiple rules, all must pass', () => {
      const verifier = makeVerifier([
        oneUpperCaseRule,
        oneLowerCaseRule,
        oneNumberRule
      ]);

      const result = verifier.verify('Abc123');

      expect(result.passed).toBe(true);
    });

    test('with multiple failing rules, returns all errors', () => {
      const verifier = makeVerifier([
        oneUpperCaseRule,
        oneNumberRule
      ]);

      const result = verifier.verify('abc');

      expect(result.passed).toBe(false);
      expect(result.errors).toHaveLength(2);
      expect(result.errors).toContain('Must have at least one uppercase letter');
      expect(result.errors).toContain('Must have at least one number');
    });
  });

  describe('oneUpperCaseRule', () => {
    test.each([
      ['Abc', true],
      ['aBc', true],
      ['ABC', true],
      ['AbC123', true],
    ])('given %s with uppercase, returns true', (input, expected) => {
      const result = oneUpperCaseRule(input);
      expect(result.passed).toBe(expected);
    });

    test.each([
      ['abc', false],
      ['123', false],
      ['abc123', false],
    ])('given %s without uppercase, returns false', (input, expected) => {
      const result = oneUpperCaseRule(input);
      expect(result.passed).toBe(expected);
    });
  });
});
```

## Testing Different Exit Points

### Return Value Exit Point

```javascript
// calculator.js
const calculateTotal = (items) => {
  return items.reduce((sum, item) => sum + item.price, 0);
};

// calculator.test.js
test('calculateTotal with multiple items returns sum', () => {
  const items = [
    { name: 'apple', price: 1.50 },
    { name: 'banana', price: 0.75 },
    { name: 'orange', price: 2.00 }
  ];

  const total = calculateTotal(items);

  expect(total).toBe(4.25);
});

test('calculateTotal with empty array returns zero', () => {
  expect(calculateTotal([])).toBe(0);
});
```

### State-Based Exit Point

```javascript
// shopping-cart.js
class ShoppingCart {
  constructor() {
    this.items = [];
    this.total = 0;
  }

  addItem(item) {
    this.items.push(item);
    this.total += item.price;
  }

  removeItem(itemName) {
    const index = this.items.findIndex(item => item.name === itemName);
    if (index !== -1) {
      this.total -= this.items[index].price;
      this.items.splice(index, 1);
    }
  }

  itemCount() {
    return this.items.length;
  }

  getTotal() {
    return this.total;
  }
}

// shopping-cart.test.js
describe('ShoppingCart', () => {
  const makeCart = () => new ShoppingCart();

  test('new cart has zero items', () => {
    const cart = makeCart();
    expect(cart.itemCount()).toBe(0);
  });

  test('addItem increases item count', () => {
    const cart = makeCart();

    cart.addItem({ name: 'apple', price: 1.50 });

    expect(cart.itemCount()).toBe(1);
  });

  test('addItem updates total', () => {
    const cart = makeCart();

    cart.addItem({ name: 'apple', price: 1.50 });
    cart.addItem({ name: 'banana', price: 0.75 });

    expect(cart.getTotal()).toBe(2.25);
  });

  test('removeItem decreases item count', () => {
    const cart = makeCart();
    cart.addItem({ name: 'apple', price: 1.50 });

    cart.removeItem('apple');

    expect(cart.itemCount()).toBe(0);
  });

  test('removeItem updates total', () => {
    const cart = makeCart();
    cart.addItem({ name: 'apple', price: 1.50 });
    cart.addItem({ name: 'banana', price: 0.75 });

    cart.removeItem('apple');

    expect(cart.getTotal()).toBe(0.75);
  });
});
```

### Third-Party Call Exit Point (Mock)

```javascript
// user-service.js
class UserService {
  constructor(database, logger) {
    this.database = database;
    this.logger = logger;
  }

  async createUser(userData) {
    this.logger.info('Creating user', { email: userData.email });

    const user = await this.database.save('users', userData);

    this.logger.info('User created', { userId: user.id });

    return user;
  }
}

// user-service.test.js
describe('UserService', () => {
  const makeService = (database, logger) => {
    return new UserService(database, logger);
  };

  test('createUser saves to database', async () => {
    const stubDatabase = {
      save: jest.fn().mockResolvedValue({ id: 1, name: 'John' })
    };
    const stubLogger = { info: jest.fn() };
    const service = makeService(stubDatabase, stubLogger);

    await service.createUser({ name: 'John', email: 'john@example.com' });

    expect(stubDatabase.save).toHaveBeenCalledWith(
      'users',
      { name: 'John', email: 'john@example.com' }
    );
  });

  test('createUser logs user creation', async () => {
    const stubDatabase = {
      save: jest.fn().mockResolvedValue({ id: 1, name: 'John' })
    };
    const mockLogger = { info: jest.fn() };
    const service = makeService(stubDatabase, mockLogger);

    await service.createUser({ name: 'John', email: 'john@example.com' });

    expect(mockLogger.info).toHaveBeenCalledWith(
      'Creating user',
      { email: 'john@example.com' }
    );
    expect(mockLogger.info).toHaveBeenCalledWith(
      'User created',
      { userId: 1 }
    );
  });

  test('createUser returns saved user', async () => {
    const expectedUser = { id: 1, name: 'John', email: 'john@example.com' };
    const stubDatabase = {
      save: jest.fn().mockResolvedValue(expectedUser)
    };
    const stubLogger = { info: jest.fn() };
    const service = makeService(stubDatabase, stubLogger);

    const result = await service.createUser({ name: 'John' });

    expect(result).toEqual(expectedUser);
  });
});
```

## Dependency Injection Examples

### Parameter Injection

```javascript
// time-checker.js
const SATURDAY = 6, SUNDAY = 0;

const isWeekend = (currentDay) => {
  return [SATURDAY, SUNDAY].includes(currentDay);
};

const verifyPassword = (input, rules, currentDay) => {
  if (isWeekend(currentDay)) {
    throw new Error("It's the weekend!");
  }

  // Validation logic...
  return { passed: true };
};

// time-checker.test.js
describe('verifyPassword', () => {
  const MONDAY = 1;

  test('on weekdays, processes normally', () => {
    const result = verifyPassword('Abc123', [], MONDAY);
    expect(result.passed).toBe(true);
  });

  test('on weekends, throws exception', () => {
    expect(() => verifyPassword('Abc123', [], SUNDAY))
      .toThrow("It's the weekend!");
  });
});
```

### Functional Injection

```javascript
// logger.js
const createLogger = (logFn = console.log) => {
  return {
    info: (message, data) => {
      logFn(`INFO: ${message}`, data);
    },
    error: (message, data) => {
      logFn(`ERROR: ${message}`, data);
    }
  };
};

const createUserService = (logger) => {
  return {
    createUser: (userData) => {
      logger.info('Creating user', userData);
      // User creation logic...
      return { id: 1, ...userData };
    }
  };
};

// logger.test.js
describe('createUserService', () => {
  test('createUser logs creation', () => {
    const logs = [];
    const testLogger = createLogger((msg, data) => logs.push({ msg, data }));
    const service = createUserService(testLogger);

    service.createUser({ name: 'John' });

    expect(logs).toHaveLength(1);
    expect(logs[0].msg).toContain('Creating user');
    expect(logs[0].data).toEqual({ name: 'John' });
  });
});
```

### Constructor Injection (TypeScript)

```typescript
// user-repository.ts
interface IDatabase {
  query(sql: string, params: any[]): Promise<any>;
}

interface ILogger {
  info(message: string): void;
  error(message: string, error: Error): void;
}

class UserRepository {
  constructor(
    private database: IDatabase,
    private logger: ILogger
  ) {}

  async findById(userId: number): Promise<User | null> {
    this.logger.info(`Finding user ${userId}`);

    try {
      const result = await this.database.query(
        'SELECT * FROM users WHERE id = ?',
        [userId]
      );

      return result.rows[0] || null;
    } catch (error) {
      this.logger.error('Database query failed', error);
      throw error;
    }
  }
}

// user-repository.test.ts
describe('UserRepository', () => {
  const makeRepository = (database: IDatabase, logger: ILogger) => {
    return new UserRepository(database, logger);
  };

  test('findById queries database with correct SQL', async () => {
    const mockDatabase = {
      query: jest.fn().mockResolvedValue({ rows: [{ id: 1, name: 'John' }] })
    };
    const stubLogger = { info: jest.fn(), error: jest.fn() };
    const repository = makeRepository(mockDatabase, stubLogger);

    await repository.findById(1);

    expect(mockDatabase.query).toHaveBeenCalledWith(
      'SELECT * FROM users WHERE id = ?',
      [1]
    );
  });

  test('findById returns user when found', async () => {
    const expectedUser = { id: 1, name: 'John' };
    const stubDatabase = {
      query: jest.fn().mockResolvedValue({ rows: [expectedUser] })
    };
    const stubLogger = { info: jest.fn(), error: jest.fn() };
    const repository = makeRepository(stubDatabase, stubLogger);

    const user = await repository.findById(1);

    expect(user).toEqual(expectedUser);
  });

  test('findById returns null when not found', async () => {
    const stubDatabase = {
      query: jest.fn().mockResolvedValue({ rows: [] })
    };
    const stubLogger = { info: jest.fn(), error: jest.fn() };
    const repository = makeRepository(stubDatabase, stubLogger);

    const user = await repository.findById(999);

    expect(user).toBeNull();
  });

  test('findById logs error on database failure', async () => {
    const dbError = new Error('Connection failed');
    const stubDatabase = {
      query: jest.fn().mockRejectedValue(dbError)
    };
    const mockLogger = { info: jest.fn(), error: jest.fn() };
    const repository = makeRepository(stubDatabase, mockLogger);

    await expect(repository.findById(1)).rejects.toThrow('Connection failed');

    expect(mockLogger.error).toHaveBeenCalledWith(
      'Database query failed',
      dbError
    );
  });
});
```

## Async Testing Examples

### Extract Entry Point Pattern

```javascript
// website-verifier.js
const fetch = require('node-fetch');

// Main entry point - still async, still makes real network call
const isWebsiteAlive = async () => {
  try {
    const resp = await fetch('http://example.com');
    throwIfResponseNotOK(resp);
    const text = await resp.text();
    return processFetchContent(text);
  } catch (err) {
    return processFetchError(err);
  }
};

const throwIfResponseNotOK = (resp) => {
  if (!resp.ok) {
    throw new Error(resp.statusText);
  }
};

// New entry points - pure logic, easy to test!
const processFetchContent = (text) => {
  if (text.includes('illustrative')) {
    return { success: true, status: 'ok' };
  }
  return { success: false, status: 'missing text' };
};

const processFetchError = (err) => {
  return { success: false, status: err.message || err };
};

module.exports = {
  isWebsiteAlive,
  processFetchContent,
  processFetchError
};

// website-verifier.test.js
describe('website verification', () => {
  // Unit tests - fast, synchronous, easy to simulate scenarios
  describe('processFetchContent', () => {
    test('with keyword present, returns success', () => {
      const result = processFetchContent('This is illustrative content');

      expect(result.success).toBe(true);
      expect(result.status).toBe('ok');
    });

    test('with keyword missing, returns failure', () => {
      const result = processFetchContent('Other content here');

      expect(result.success).toBe(false);
      expect(result.status).toBe('missing text');
    });

    test('with empty content, returns failure', () => {
      const result = processFetchContent('');

      expect(result.success).toBe(false);
    });
  });

  describe('processFetchError', () => {
    test('with error message, returns failure with message', () => {
      const result = processFetchError(new Error('Network timeout'));

      expect(result.success).toBe(false);
      expect(result.status).toBe('Network timeout');
    });

    test('with string error, returns failure', () => {
      const result = processFetchError('Server error');

      expect(result.success).toBe(false);
      expect(result.status).toBe('Server error');
    });
  });

  // Integration test - one or two to verify orchestration
  describe('isWebsiteAlive (integration)', () => {
    test('NETWORK REQUIRED: verifies real website', async () => {
      const result = await isWebsiteAlive();

      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('status');
    }, 10000); // Longer timeout for real network
  });
});
```

### Extract Adapter Pattern

```javascript
// network-adapter.js
const fetch = require('node-fetch');

const fetchUrlText = async (url) => {
  try {
    const resp = await fetch(url);
    if (resp.ok) {
      const text = await resp.text();
      return { ok: true, text };
    }
    return { ok: false, text: resp.statusText };
  } catch (error) {
    return { ok: false, text: error.message };
  }
};

module.exports = { fetchUrlText };

// website-checker.js
const isWebsiteAlive = async (network, url = 'http://example.com') => {
  const result = await network.fetchUrlText(url);

  if (!result.ok) {
    return { success: false, status: result.text };
  }

  const hasKeyword = result.text.includes('illustrative');
  return hasKeyword
    ? { success: true, status: 'ok' }
    : { success: false, status: 'missing text' };
};

module.exports = { isWebsiteAlive };

// website-checker.test.js
const { isWebsiteAlive } = require('./website-checker');

describe('isWebsiteAlive', () => {
  const makeFakeNetwork = (response) => ({
    fetchUrlText: () => response
  });

  test('with successful fetch and keyword, returns success', async () => {
    const fakeNetwork = makeFakeNetwork({
      ok: true,
      text: 'This is illustrative content'
    });

    const result = await isWebsiteAlive(fakeNetwork);

    expect(result.success).toBe(true);
    expect(result.status).toBe('ok');
  });

  test('with successful fetch but no keyword, returns failure', async () => {
    const fakeNetwork = makeFakeNetwork({
      ok: true,
      text: 'Different content'
    });

    const result = await isWebsiteAlive(fakeNetwork);

    expect(result.success).toBe(false);
    expect(result.status).toBe('missing text');
  });

  test('with network error, returns failure', async () => {
    const fakeNetwork = makeFakeNetwork({
      ok: false,
      text: 'Network timeout'
    });

    const result = await isWebsiteAlive(fakeNetwork);

    expect(result.success).toBe(false);
    expect(result.status).toBe('Network timeout');
  });

  test('with custom URL, passes to network adapter', async () => {
    const mockNetwork = {
      fetchUrlText: jest.fn().mockResolvedValue({
        ok: true,
        text: 'illustrative'
      })
    };

    await isWebsiteAlive(mockNetwork, 'http://custom.com');

    expect(mockNetwork.fetchUrlText).toHaveBeenCalledWith('http://custom.com');
  });
});
```

### Testing Timers

```javascript
// delayed-processor.js
const processAfterDelay = (data, callback, delay = 1000) => {
  setTimeout(() => {
    const processed = data.toUpperCase();
    callback(processed);
  }, delay);
};

const scheduleCleanup = (cleanupFn) => {
  return setInterval(() => {
    cleanupFn();
  }, 5000);
};

module.exports = { processAfterDelay, scheduleCleanup };

// delayed-processor.test.js
describe('processAfterDelay', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  test('calls callback after specified delay', () => {
    const callback = jest.fn();

    processAfterDelay('hello', callback, 1000);

    expect(callback).not.toHaveBeenCalled();

    jest.advanceTimersByTime(1000);

    expect(callback).toHaveBeenCalledWith('HELLO');
  });

  test('processes data before calling callback', () => {
    const callback = jest.fn();

    processAfterDelay('test', callback, 500);
    jest.advanceTimersByTime(500);

    expect(callback).toHaveBeenCalledWith('TEST');
  });

  test('works with custom delay', () => {
    const callback = jest.fn();

    processAfterDelay('data', callback, 2000);

    jest.advanceTimersByTime(1999);
    expect(callback).not.toHaveBeenCalled();

    jest.advanceTimersByTime(1);
    expect(callback).toHaveBeenCalled();
  });
});

describe('scheduleCleanup', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  test('calls cleanup function every 5 seconds', () => {
    const cleanupFn = jest.fn();

    scheduleCleanup(cleanupFn);

    expect(cleanupFn).not.toHaveBeenCalled();

    jest.advanceTimersByTime(5000);
    expect(cleanupFn).toHaveBeenCalledTimes(1);

    jest.advanceTimersByTime(5000);
    expect(cleanupFn).toHaveBeenCalledTimes(2);

    jest.advanceTimersByTime(5000);
    expect(cleanupFn).toHaveBeenCalledTimes(3);
  });

  test('can be cleared', () => {
    const cleanupFn = jest.fn();

    const intervalId = scheduleCleanup(cleanupFn);

    jest.advanceTimersByTime(5000);
    expect(cleanupFn).toHaveBeenCalledTimes(1);

    clearInterval(intervalId);

    jest.advanceTimersByTime(10000);
    expect(cleanupFn).toHaveBeenCalledTimes(1); // Still 1, not called again
  });
});
```

## Mock and Stub Examples

### Stub for Incoming Dependency

```javascript
// order-service.js
class OrderService {
  constructor(priceCalculator, inventory) {
    this.priceCalculator = priceCalculator;
    this.inventory = inventory;
  }

  canFulfillOrder(items) {
    // Check inventory for each item
    for (const item of items) {
      const available = this.inventory.getStock(item.productId);
      if (available < item.quantity) {
        return false;
      }
    }
    return true;
  }

  calculateTotal(items) {
    let total = 0;
    for (const item of items) {
      const price = this.priceCalculator.getPrice(item.productId);
      total += price * item.quantity;
    }
    return total;
  }
}

// order-service.test.js
describe('OrderService', () => {
  test('canFulfillOrder with sufficient stock returns true', () => {
    // Stub - provides fake data IN
    const stubInventory = {
      getStock: (productId) => {
        const stock = { 'prod-1': 100, 'prod-2': 50 };
        return stock[productId] || 0;
      }
    };
    const stubCalculator = { getPrice: () => 10 };
    const service = new OrderService(stubCalculator, stubInventory);

    const items = [
      { productId: 'prod-1', quantity: 5 },
      { productId: 'prod-2', quantity: 3 }
    ];

    const result = service.canFulfillOrder(items);

    expect(result).toBe(true);
  });

  test('canFulfillOrder with insufficient stock returns false', () => {
    const stubInventory = {
      getStock: (productId) => {
        return productId === 'prod-1' ? 100 : 2; // Only 2 of prod-2
      }
    };
    const stubCalculator = { getPrice: () => 10 };
    const service = new OrderService(stubCalculator, stubInventory);

    const items = [
      { productId: 'prod-1', quantity: 5 },
      { productId: 'prod-2', quantity: 5 } // Need 5, only have 2
    ];

    const result = service.canFulfillOrder(items);

    expect(result).toBe(false);
  });

  test('calculateTotal returns sum of item prices', () => {
    const stubInventory = { getStock: () => 100 };
    // Stub provides different prices for different products
    const stubCalculator = {
      getPrice: (productId) => {
        const prices = { 'prod-1': 10.50, 'prod-2': 5.25 };
        return prices[productId];
      }
    };
    const service = new OrderService(stubCalculator, stubInventory);

    const items = [
      { productId: 'prod-1', quantity: 2 },
      { productId: 'prod-2', quantity: 3 }
    ];

    const total = service.calculateTotal(items);

    expect(total).toBe(36.75); // (10.50 * 2) + (5.25 * 3)
  });
});
```

### Mock for Outgoing Dependency

```javascript
// order-processor.js
class OrderProcessor {
  constructor(orderRepository, emailService, logger) {
    this.orderRepository = orderRepository;
    this.emailService = emailService;
    this.logger = logger;
  }

  async processOrder(order) {
    // Save to database (outgoing dependency - exit point)
    const savedOrder = await this.orderRepository.save(order);

    // Send confirmation email (outgoing dependency - exit point)
    await this.emailService.sendOrderConfirmation(
      order.customerEmail,
      savedOrder
    );

    // Log the action (outgoing dependency - exit point)
    this.logger.info('Order processed', { orderId: savedOrder.id });

    return savedOrder;
  }
}

// order-processor.test.js
describe('OrderProcessor', () => {
  describe('processOrder', () => {
    test('saves order to repository', async () => {
      const mockRepository = {
        save: jest.fn().mockResolvedValue({ id: 1, status: 'completed' })
      };
      const stubEmailService = {
        sendOrderConfirmation: jest.fn().mockResolvedValue(true)
      };
      const stubLogger = { info: jest.fn() };
      const processor = new OrderProcessor(
        mockRepository,
        stubEmailService,
        stubLogger
      );

      const order = { customerEmail: 'test@example.com', items: [] };

      await processor.processOrder(order);

      // Assert against mock (it's an exit point)
      expect(mockRepository.save).toHaveBeenCalledWith(order);
    });

    test('sends confirmation email', async () => {
      const savedOrder = { id: 1, status: 'completed' };
      const stubRepository = {
        save: jest.fn().mockResolvedValue(savedOrder)
      };
      const mockEmailService = {
        sendOrderConfirmation: jest.fn().mockResolvedValue(true)
      };
      const stubLogger = { info: jest.fn() };
      const processor = new OrderProcessor(
        stubRepository,
        mockEmailService,
        stubLogger
      );

      const order = { customerEmail: 'test@example.com', items: [] };

      await processor.processOrder(order);

      // Assert against mock (it's an exit point)
      expect(mockEmailService.sendOrderConfirmation).toHaveBeenCalledWith(
        'test@example.com',
        savedOrder
      );
    });

    test('logs order processing', async () => {
      const savedOrder = { id: 1, status: 'completed' };
      const stubRepository = {
        save: jest.fn().mockResolvedValue(savedOrder)
      };
      const stubEmailService = {
        sendOrderConfirmation: jest.fn().mockResolvedValue(true)
      };
      const mockLogger = { info: jest.fn() };
      const processor = new OrderProcessor(
        stubRepository,
        stubEmailService,
        mockLogger
      );

      await processor.processOrder({ customerEmail: 'test@example.com' });

      // Assert against mock (it's an exit point)
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Order processed',
        { orderId: 1 }
      );
    });

    test('returns saved order', async () => {
      const savedOrder = { id: 1, status: 'completed' };
      const stubRepository = {
        save: jest.fn().mockResolvedValue(savedOrder)
      };
      const stubEmailService = {
        sendOrderConfirmation: jest.fn().mockResolvedValue(true)
      };
      const stubLogger = { info: jest.fn() };
      const processor = new OrderProcessor(
        stubRepository,
        stubEmailService,
        stubLogger
      );

      const result = await processor.processOrder({
        customerEmail: 'test@example.com'
      });

      expect(result).toEqual(savedOrder);
    });
  });
});
```

## Test Refactoring Examples

### Before and After: Removing Logic from Tests

```javascript
// ❌ BEFORE - has logic in test
describe('calculateDiscount (bad)', () => {
  test('applies correct discount for different tiers', () => {
    const tiers = [
      { name: 'bronze', threshold: 100, discount: 0.05 },
      { name: 'silver', threshold: 500, discount: 0.10 },
      { name: 'gold', threshold: 1000, discount: 0.15 }
    ];

    for (const tier of tiers) {
      const total = tier.threshold + 50;
      const result = calculateDiscount(total);

      if (tier.name === 'bronze') {
        expect(result.discount).toBe(0.05);
      } else if (tier.name === 'silver') {
        expect(result.discount).toBe(0.10);
      } else {
        expect(result.discount).toBe(0.15);
      }
    }
  });
});

// ✅ AFTER - no logic, clear assertions
describe('calculateDiscount (good)', () => {
  test('for bronze tier, applies 5% discount', () => {
    const result = calculateDiscount(150);
    expect(result.discount).toBe(0.05);
  });

  test('for silver tier, applies 10% discount', () => {
    const result = calculateDiscount(550);
    expect(result.discount).toBe(0.10);
  });

  test('for gold tier, applies 15% discount', () => {
    const result = calculateDiscount(1050);
    expect(result.discount).toBe(0.15);
  });
});
```

### Before and After: Replacing beforeEach with Factory

```javascript
// ❌ BEFORE - uses beforeEach
describe('UserManager (bad)', () => {
  let manager;
  let database;
  let logger;

  beforeEach(() => {
    database = createTestDatabase();
    logger = createTestLogger();
    manager = new UserManager(database, logger);
  });

  test('creates user', async () => {
    const user = await manager.createUser({ name: 'John' });
    expect(user.id).toBeDefined();
  });

  test('updates user', async () => {
    const user = await manager.createUser({ name: 'John' });
    await manager.updateUser(user.id, { name: 'Jane' });
    const updated = await manager.getUser(user.id);
    expect(updated.name).toBe('Jane');
  });
});

// ✅ AFTER - uses factory method
describe('UserManager (good)', () => {
  const makeManager = (database, logger) => {
    return new UserManager(
      database || createTestDatabase(),
      logger || createTestLogger()
    );
  };

  test('createUser saves to database and returns user', async () => {
    const manager = makeManager();

    const user = await manager.createUser({ name: 'John' });

    expect(user.id).toBeDefined();
    expect(user.name).toBe('John');
  });

  test('updateUser modifies existing user', async () => {
    const manager = makeManager();
    const user = await manager.createUser({ name: 'John' });

    await manager.updateUser(user.id, { name: 'Jane' });

    const updated = await manager.getUser(user.id);
    expect(updated.name).toBe('Jane');
  });

  test('createUser logs creation', async () => {
    const mockLogger = { info: jest.fn() };
    const manager = makeManager(null, mockLogger);

    await manager.createUser({ name: 'John' });

    expect(mockLogger.info).toHaveBeenCalledWith(
      'User created',
      expect.objectContaining({ name: 'John' })
    );
  });
});
```

## Common Scenarios

### Testing Error Handling

```javascript
// file-reader.js
const fs = require('fs').promises;

const readConfig = async (filePath, fileSystem = fs) => {
  try {
    const content = await fileSystem.readFile(filePath, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new Error(`Config file not found: ${filePath}`);
    }
    if (error instanceof SyntaxError) {
      throw new Error(`Invalid JSON in config file: ${filePath}`);
    }
    throw error;
  }
};

// file-reader.test.js
describe('readConfig', () => {
  test('with valid file, returns parsed JSON', async () => {
    const fakeFs = {
      readFile: jest.fn().mockResolvedValue('{"key": "value"}')
    };

    const config = await readConfig('/path/to/config.json', fakeFs);

    expect(config).toEqual({ key: 'value' });
  });

  test('with missing file, throws descriptive error', async () => {
    const fakeFs = {
      readFile: jest.fn().mockRejectedValue({ code: 'ENOENT' })
    };

    await expect(readConfig('/missing.json', fakeFs))
      .rejects
      .toThrow('Config file not found: /missing.json');
  });

  test('with invalid JSON, throws descriptive error', async () => {
    const fakeFs = {
      readFile: jest.fn().mockResolvedValue('{invalid json}')
    };

    await expect(readConfig('/invalid.json', fakeFs))
      .rejects
      .toThrow('Invalid JSON in config file: /invalid.json');
  });

  test('with other errors, rethrows original error', async () => {
    const originalError = new Error('Permission denied');
    const fakeFs = {
      readFile: jest.fn().mockRejectedValue(originalError)
    };

    await expect(readConfig('/file.json', fakeFs))
      .rejects
      .toThrow('Permission denied');
  });
});
```

### Testing Event Emitters

```javascript
// event-processor.js
const EventEmitter = require('events');

class DataProcessor extends EventEmitter {
  processData(data) {
    this.emit('processing-started', { dataSize: data.length });

    try {
      const result = data.map(item => item * 2);

      this.emit('processing-completed', {
        itemsProcessed: result.length
      });

      return result;
    } catch (error) {
      this.emit('processing-failed', { error });
      throw error;
    }
  }
}

// event-processor.test.js
describe('DataProcessor', () => {
  test('emits processing-started event', () => {
    const processor = new DataProcessor();
    const listener = jest.fn();
    processor.on('processing-started', listener);

    processor.processData([1, 2, 3]);

    expect(listener).toHaveBeenCalledWith({ dataSize: 3 });
  });

  test('emits processing-completed event', () => {
    const processor = new DataProcessor();
    const listener = jest.fn();
    processor.on('processing-completed', listener);

    processor.processData([1, 2, 3]);

    expect(listener).toHaveBeenCalledWith({ itemsProcessed: 3 });
  });

  test('returns processed data', () => {
    const processor = new DataProcessor();

    const result = processor.processData([1, 2, 3]);

    expect(result).toEqual([2, 4, 6]);
  });

  test('emits processing-failed on error', () => {
    const processor = new DataProcessor();
    const listener = jest.fn();
    processor.on('processing-failed', listener);

    // Trigger error by passing null (map will fail)
    expect(() => processor.processData(null)).toThrow();

    expect(listener).toHaveBeenCalledWith({
      error: expect.any(Error)
    });
  });
});
```

### Testing Cached/Memoized Functions

```javascript
// cache-service.js
class CacheService {
  constructor(expensiveOperation) {
    this.expensiveOperation = expensiveOperation;
    this.cache = new Map();
  }

  get(key) {
    if (this.cache.has(key)) {
      return this.cache.get(key);
    }

    const value = this.expensiveOperation(key);
    this.cache.set(key, value);
    return value;
  }

  clear() {
    this.cache.clear();
  }
}

// cache-service.test.js
describe('CacheService', () => {
  test('calls expensive operation on first access', () => {
    const mockOperation = jest.fn().mockReturnValue('result');
    const service = new CacheService(mockOperation);

    service.get('key1');

    expect(mockOperation).toHaveBeenCalledWith('key1');
    expect(mockOperation).toHaveBeenCalledTimes(1);
  });

  test('returns cached value on subsequent access', () => {
    const mockOperation = jest.fn().mockReturnValue('result');
    const service = new CacheService(mockOperation);

    const result1 = service.get('key1');
    const result2 = service.get('key1');
    const result3 = service.get('key1');

    expect(result1).toBe('result');
    expect(result2).toBe('result');
    expect(result3).toBe('result');
    expect(mockOperation).toHaveBeenCalledTimes(1); // Only called once!
  });

  test('calls operation again for different keys', () => {
    const mockOperation = jest.fn()
      .mockReturnValueOnce('result1')
      .mockReturnValueOnce('result2');
    const service = new CacheService(mockOperation);

    service.get('key1');
    service.get('key2');

    expect(mockOperation).toHaveBeenCalledTimes(2);
    expect(mockOperation).toHaveBeenCalledWith('key1');
    expect(mockOperation).toHaveBeenCalledWith('key2');
  });

  test('clear removes all cached values', () => {
    const mockOperation = jest.fn().mockReturnValue('result');
    const service = new CacheService(mockOperation);

    service.get('key1');
    service.clear();
    service.get('key1');

    expect(mockOperation).toHaveBeenCalledTimes(2); // Called again after clear
  });
});
```

## Related Resources

- Main documentation: [SKILL.md](SKILL.md)
- Reference guide: [REFERENCE.md](REFERENCE.md)
- Code repository: https://github.com/royosherove/aout3-samples
- Jest documentation: https://jestjs.io/
