import SwiftUI
import Domain

/// The shared row for any user list — the browse list, the related list, the
/// multi-select picker. Pure presentation of a `User`; each screen wraps it in
/// its own button/selection affordance.
struct UserRow: View {
    let user: User

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name).font(.headline)
                Text(user.email).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if user.isFavorite {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
            }
        }
    }
}
