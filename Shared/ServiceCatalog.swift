import Foundation

enum ServiceCatalog: Sendable {
    static let all: [ServiceDefinition] = [
        service(
            id: "tiktok",
            name: "TikTok",
            image: "music.note.tv",
            summary: "Traffic matching TikTok and ByteDance delivery domains.",
            domains: [
                "tiktok.com",
                "tiktokv.com",
                "tiktokcdn.com",
                "tiktokcdn-us.com",
                "musical.ly",
                "byteoversea.com",
                "ibyteimg.com",
                "byteintlapi.com"
            ],
            ipv4: ["162.159.128.0/19"],
            ipv6: ["2606:4700::/32"]
        ),
        service(
            id: "youtube",
            name: "YouTube",
            image: "play.rectangle",
            summary: "Traffic matching YouTube and googlevideo domains — not all of Google.",
            domains: [
                "youtube.com",
                "youtu.be",
                "youtubei.googleapis.com",
                "ytimg.com",
                "googlevideo.com",
                "yt3.ggpht.com",
                "youtube-nocookie.com"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "instagram",
            name: "Instagram",
            image: "camera",
            summary: "Instagram domains only. This does not claim every Facebook destination.",
            domains: [
                "instagram.com",
                "cdninstagram.com",
                "igcdn.com"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "x",
            name: "X",
            image: "n.square",
            summary: "Traffic matching X and Twitter delivery domains.",
            domains: [
                "x.com",
                "twitter.com",
                "twimg.com",
                "t.co",
                "pscp.tv"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "reddit",
            name: "Reddit",
            image: "text.bubble",
            summary: "Traffic matching Reddit and redditstatic / redd.it domains.",
            domains: [
                "reddit.com",
                "redditstatic.com",
                "redd.it",
                "redditmedia.com"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "discord",
            name: "Discord",
            image: "bubble.left.and.bubble.right",
            summary: "Traffic matching Discord client and media domains.",
            domains: [
                "discord.com",
                "discordapp.com",
                "discord.gg",
                "discordapp.net"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "telegram",
            name: "Telegram",
            image: "paperplane",
            summary: "Traffic matching Telegram domains. IP ranges change; domain rules are primary.",
            domains: [
                "telegram.org",
                "t.me",
                "telegra.ph"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "whatsapp",
            name: "WhatsApp",
            image: "phone.bubble",
            summary: "WhatsApp domains. Shared Meta infrastructure can still produce edge cases.",
            domains: [
                "whatsapp.com",
                "whatsapp.net"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "signal",
            name: "Signal",
            image: "lock.shield",
            summary: "Traffic matching Signal service domains.",
            domains: [
                "signal.org",
                "whispersystems.org"
            ],
            ipv4: [],
            ipv6: []
        ),
        service(
            id: "twitch",
            name: "Twitch",
            image: "dot.radiowaves.left.and.right",
            summary: "Traffic matching Twitch and jtvnw delivery domains.",
            domains: [
                "twitch.tv",
                "ttvnw.net",
                "jtvnw.net",
                "twitchcdn.net"
            ],
            ipv4: [],
            ipv6: []
        )
    ]

    static func service(id: String) -> ServiceDefinition? {
        all.first { $0.id == id }
    }

    static func services(ids: [String]) -> [ServiceDefinition] {
        let set = Set(ids)
        return all.filter { set.contains($0.id) }
    }

    static func combinedRule(for ids: [String]) -> RoutingRule {
        let selected = services(ids: ids)
        return RoutingRule(
            id: "combined",
            domains: selected.flatMap(\.rule.domains),
            ipv4CIDRs: selected.flatMap(\.rule.ipv4CIDRs),
            ipv6CIDRs: selected.flatMap(\.rule.ipv6CIDRs)
        )
    }

    private static func service(
        id: String,
        name: String,
        image: String,
        summary: String,
        domains: [String],
        ipv4: [String],
        ipv6: [String]
    ) -> ServiceDefinition {
        ServiceDefinition(
            id: id,
            name: name,
            systemImage: image,
            summary: summary,
            rule: RoutingRule(
                id: id,
                domains: domains.map { $0.lowercased() },
                ipv4CIDRs: ipv4.compactMap(NetworkCIDR.init(presentation:)),
                ipv6CIDRs: ipv6.compactMap(NetworkCIDR.init(presentation:))
            )
        )
    }
}
