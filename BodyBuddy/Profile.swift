//
//  Profile.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let isAdmin: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case isAdmin = "is_admin"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
