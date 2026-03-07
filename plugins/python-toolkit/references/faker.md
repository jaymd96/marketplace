# Faker v33.0+

Fake data generation for testing, fixtures, and database seeding.

## Quick Start

```python
from faker import Faker

fake = Faker()
print(fake.name())       # 'John Smith'
print(fake.email())      # 'john.smith@example.com'
print(fake.address())    # '123 Main St\nAnytown, NY 12345'
print(fake.text())       # Lorem-ipsum paragraph
```

## Core API

### Creating Instances

```python
from faker import Faker

fake = Faker()                          # Default: en_US
fake = Faker("de_DE")                   # German locale
fake = Faker(["en_US", "ja_JP"])        # Multi-locale (randomly picks locale per call)
```

### Common Providers

```python
# Identity
fake.name()                  # "John Smith"
fake.first_name()            # "John"
fake.last_name()             # "Smith"
fake.prefix()                # "Mr."
fake.suffix()                # "Jr."

# Contact
fake.email()                 # "user@example.com"
fake.safe_email()            # Always uses example.com/org/net
fake.phone_number()          # "(555) 123-4567"
fake.company_email()         # "jsmith@company.com"

# Address
fake.address()               # Full multi-line address
fake.street_address()        # "123 Main St"
fake.city()                  # "Springfield"
fake.state()                 # "California"
fake.zipcode()               # "90210"
fake.country()               # "United States"
fake.latitude()              # Decimal
fake.longitude()             # Decimal

# Text
fake.text(max_nb_chars=200)  # Paragraph
fake.sentence()              # Single sentence
fake.paragraph()             # Single paragraph
fake.word()                  # Single word
fake.words(nb=5)             # List of words

# Internet
fake.url()                   # "https://example.com/"
fake.domain_name()           # "example.com"
fake.ipv4()                  # "192.168.1.1"
fake.ipv6()                  # "2001:db8::1"
fake.user_agent()            # Browser user-agent string
fake.slug()                  # "lorem-ipsum-dolor"
fake.uuid4()                 # UUID string

# Date/Time
fake.date()                  # "2024-01-15"
fake.date_time()             # datetime object
fake.date_between(start_date="-1y", end_date="today")
fake.date_time_this_year()
fake.iso8601()               # "2024-01-15T12:30:00"
fake.unix_time()             # Epoch timestamp

# Financial
fake.credit_card_number()
fake.credit_card_provider()  # "Visa"
fake.currency_code()         # "USD"
fake.iban()

# File
fake.file_name()             # "report.pdf"
fake.file_path()             # "/home/user/report.pdf"
fake.mime_type()             # "application/json"

# Structured
fake.json(num_rows=5)
fake.csv(num_rows=10)
fake.profile()               # Dict with name, address, job, etc.
fake.simple_profile()        # Minimal profile dict
```

### Seeding for Reproducibility

```python
# Global seed (affects all instances using shared random)
Faker.seed(12345)

# Instance seed (only affects this instance)
fake = Faker()
fake.seed_instance(12345)

# Reproducible output
fake = Faker()
fake.seed_instance(0)
print(fake.name())  # Always the same name for seed 0
```

### Custom Providers

```python
from faker import Faker
from faker.providers import BaseProvider

class GameProvider(BaseProvider):
    def game_title(self):
        titles = ["Chess", "Go", "Backgammon", "Risk"]
        return self.random_element(titles)

    def difficulty(self):
        return self.random_element(["easy", "medium", "hard"])

fake = Faker()
fake.add_provider(GameProvider)
print(fake.game_title())   # "Chess"
print(fake.difficulty())   # "medium"
```

## Examples

### pytest Fixture (Built-in)

```python
# Faker provides a built-in pytest fixture called `faker`
def test_user_creation(faker):
    user = User(
        name=faker.name(),
        email=faker.email(),
        joined=faker.date_this_year(),
    )
    assert "@" in user.email

# Configure via conftest.py
import pytest

@pytest.fixture
def faker():
    fake = Faker(["en_US", "en_GB"])
    fake.seed_instance(42)
    return fake
```

### Generating Test Datasets

```python
from faker import Faker

fake = Faker()
fake.seed_instance(0)

users = [
    {
        "id": i,
        "name": fake.name(),
        "email": fake.unique.email(),    # .unique guarantees no duplicates
        "signup": fake.date_this_year().isoformat(),
    }
    for i in range(100)
]
```

### Localized Data

```python
fake_de = Faker("de_DE")
print(fake_de.name())       # "Hans Mueller"
print(fake_de.address())    # German-formatted address
print(fake_de.phone_number())

fake_jp = Faker("ja_JP")
print(fake_jp.name())       # Japanese name in kanji
```

## Pitfalls

- **Results are NOT stable across library versions.** Seeded output may change between Faker releases because the underlying data pools are updated. Do not use seeds for snapshot-style assertions.
- **`.unique` has a finite pool.** Calling `fake.unique.email()` enough times will raise `UniquenessException`. Call `fake.unique.clear()` between test cases if reusing a fixture.
- **Multi-locale instances pick a locale randomly per call.** The data might be a Japanese name with a US address. If you need consistent locale per record, use a single-locale instance.
- **`fake.seed(N)` seeds the shared class-level random** -- it affects ALL Faker instances. Prefer `fake.seed_instance(N)` for test isolation.
- **Performance at scale:** Generating millions of records is slow because each call goes through provider logic. For bulk data, generate a smaller set and repeat or use `fake.csv()` / `fake.json()`.
- **The built-in `faker` pytest fixture uses `Faker()` with no seed.** Override it in conftest.py if you need determinism.
