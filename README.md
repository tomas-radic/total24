# TOtal - Topoľčianska tenisová amatérska liga

TOtal is a Ruby on Rails web application designed to manage the amateur tennis league in Topoľčany. It provides a platform for players to track their progress, manage matches, view rankings, and stay updated with the latest league news and tournaments.

### 🎾 Features

- **Player Management**: Secure registration and authentication (via Devise), profile management, and GDPR-compliant anonymization.
- **Season Tracking**: Support for multiple seasons with historical data.
- **Match Management**:
    - Support for both **Singles** and **Doubles** matches.
    - Match challenge system (requesting, accepting, rejecting, and canceling matches).
    - Score recording and winner verification.
- **Standings & Statistics**: Real-time league tables and player statistics.
- **Tournaments**: Management of league tournaments including scheduling and info.
- **News & Articles**: CMS-like features for league managers to publish updates.
- **Notifications**: In-app notifications for match requests and updates.
- **Interactive Features**: Match predictions and reactions for players.

### 🛠 Tech Stack

- **Framework**: Ruby on Rails 8.1.1
- **Ruby Version**: 3.3.6
- **Database**: SQLite (development/test), PostgreSQL (production)
- **Frontend**:
    - Hotwire (Turbo & Stimulus)
    - Bootstrap 5
    - Sass
- **Testing**: RSpec, Capybara, FactoryBot
- **Key Gems**: Devise (auth), Pundit (authorization), Noticed (notifications), Kaminari (pagination).

### 🚀 Getting Started

#### Prerequisites

- Ruby 3.3.6
- SQLite3
- Node.js & Yarn (if managing assets outside of import maps)

#### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd total24
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Database setup**:
   ```bash
   bin/rails db:prepare
   ```

4. **Start the application**:
   ```bash
   bin/dev
   # OR
   bin/rails server
   ```

### 🧪 Running Tests

The project uses RSpec for testing.

```bash
bundle exec rspec
```

### 🐳 Docker Support

The project includes a `Dockerfile` and `docker-compose.yml` for containerized environments.

```bash
docker-compose up
```

### 🌐 Localization

The application is primarily localized for the Slovak language (`sk`), targeting the local tennis community in Topoľčany.
