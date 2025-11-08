# IMDb App Clone

IMDb Clone is a Flutter-based mobile application that allows users to browse movies, view details, and manage their favorite movies. The app is designed to provide a seamless and visually appealing experience for movie enthusiasts.

## Features

- **Movie List**: Browse a list of movies with details such as title, year, genre, and ratings.
- **Movie Details**: View detailed information about a movie, including its director, cast, duration, and availability on streaming platforms.
- **Favorites Management**: Add or remove movies from your favorites list.
- **Offline Support**: Cached movie data for quick access without an internet connection.
- **Responsive Design**: Optimized for both mobile and tablet devices.

## Screenshots

![Home page](/assets/screenshots/home_page.png "Home page")

![Movie Details](/assets/screenshots/movie_details.png "Movie Details")

![Favorites](/assets/screenshots/favorites.png "Favorites")

## Getting Started

### Prerequisites

- Flutter SDK: [Install Flutter](https://docs.flutter.dev/get-started/install)
- Dart: Included with Flutter
- Android Studio or Xcode for running the app on Android/iOS devices

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/imdbclone.git
   cd imdbclone
2. Install dependencies:
    ```bash
    flutter pub get
3. Run the app
    ```bash
    flutter run

## Project Structure

- **`lib/`**: Contains the main application code;
    - **`main.dart`**: Entry point of the app;
    - **`MovieListPage`**: Display the list of movies;
    - **`MovieDetailPage`**: Shows detailed information about a selected movie;
    - **`FavoritesPage`**: Manages he user's favorite movies;
- **`assets/movies.json`**: Contains sample movie data in the app;
- **`pubspec.yaml`**: Lists dependencies and assets used in the project.

## Dependencies

- Flutter;
- Provider: State management;
- Shared Preferences: Persistent storage;
- Material Icons: For UI icons.

## Contributing
1. **Movie Data**: The app fetches movie from the **`assets/movies.json`** file;
2. **Favorites**: Favorites are stored locally using **`SharedPreferences`**;
3. **Navigation**: The app uses **`Navigatior`** for routing pages.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments
- Flutter for the framework
- IMDb for inspiration
- Material Design for design guidelines