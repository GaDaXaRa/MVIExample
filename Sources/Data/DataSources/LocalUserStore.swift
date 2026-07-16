import Domain

/// In-memory cache standing in for a local database (e.g. SwiftData/SQLite).
/// It is the single source of truth for favorite state and newly created
/// users, so the repository always has consistent data to hand back.
actor LocalUserStore {
    private var usersByID: [User.ID: User] = [:]

    func cache(_ users: [User]) {
        for user in users {
            // Never overwrite a locally-known favorite with stale remote data.
            let existingFavorite = usersByID[user.id]?.isFavorite ?? user.isFavorite
            var merged = user
            merged.isFavorite = existingFavorite
            usersByID[user.id] = merged
        }
    }

    func cache(_ user: User) {
        usersByID[user.id] = user
    }

    func user(id: User.ID) -> User? {
        usersByID[id]
    }

    func allUsers() -> [User] {
        Array(usersByID.values)
    }

    func setFavorite(id: User.ID, isFavorite: Bool) {
        usersByID[id]?.isFavorite = isFavorite
    }
}
