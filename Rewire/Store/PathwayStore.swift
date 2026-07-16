import Foundation
import Observation

/// Single source of truth. Loads synchronously on init (the file is tiny),
/// saves with a short debounce using an atomic replace so the JSON on disk is
/// never torn. Everything lives on device; there is no backend.
@Observable
final class PathwayStore {
    private(set) var pathways: [Pathway] = []

    /// Rep totals from pathways that were permanently deleted, so lifetime
    /// stats never silently shrink.
    private(set) var retiredReps: Int = 0
    private(set) var retiredRepLog: [String: Int] = [:]

    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let fileURL: URL

    // MARK: Init & persistence

    init(filename: String = "rewire.json") {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        try? FileManager.default.createDirectory(
            at: support, withIntermediateDirectories: true
        )
        fileURL = support.appendingPathComponent(filename)
        load()
    }

    private struct Snapshot: Codable {
        var pathways: [Pathway]
        var retiredReps: Int
        var retiredRepLog: [String: Int]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let snapshot = try? decoder.decode(Snapshot.self, from: data) {
            pathways = snapshot.pathways
            retiredReps = snapshot.retiredReps
            retiredRepLog = snapshot.retiredRepLog
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = Snapshot(
            pathways: pathways,
            retiredReps: retiredReps,
            retiredRepLog: retiredRepLog
        )
        let url = fileURL
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(snapshot) else { return }
            let temp = url.deletingLastPathComponent()
                .appendingPathComponent(UUID().uuidString + ".tmp")
            do {
                try data.write(to: temp, options: .atomic)
                _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
            } catch {
                try? FileManager.default.removeItem(at: temp)
            }
        }
    }

    // MARK: Collections

    var active: [Pathway] {
        pathways.filter { !$0.isArchived }
    }

    var archived: [Pathway] {
        pathways.filter(\.isArchived)
            .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
    }

    func pathway(id: Pathway.ID) -> Pathway? {
        pathways.first { $0.id == id }
    }

    // MARK: Aggregate stats (active + retired history)

    var totalReps: Int {
        pathways.reduce(retiredReps) { $0 + $1.lifetimeReps }
    }

    var todayReps: Int {
        pathways.reduce(retiredRepLog[DayKey.today] ?? 0) { $0 + $1.todayReps }
    }

    var practicedTodayCount: Int {
        active.count(where: \.practicedToday)
    }

    // MARK: Mutations

    func add(_ pathway: Pathway) {
        pathways.append(pathway)
        scheduleSave()
    }

    func update(_ pathway: Pathway) {
        guard let index = pathways.firstIndex(where: { $0.id == pathway.id }) else { return }
        pathways[index] = pathway
        scheduleSave()
    }

    /// Logs one completed rep and reports whether it crossed a maturity
    /// threshold (so the UI can celebrate).
    @discardableResult
    func logRep(for id: Pathway.ID) -> (pathway: Pathway, advancedTo: MaturityStage?)? {
        guard let index = pathways.firstIndex(where: { $0.id == id }) else { return nil }
        let before = pathways[index].maturity
        pathways[index].logRep()
        scheduleSave()
        let after = pathways[index].maturity
        return (pathways[index], after > before ? after : nil)
    }

    func archive(_ id: Pathway.ID) {
        guard let index = pathways.firstIndex(where: { $0.id == id }) else { return }
        pathways[index].archivedAt = .now
        scheduleSave()
    }

    func reactivate(_ id: Pathway.ID) {
        guard let index = pathways.firstIndex(where: { $0.id == id }) else { return }
        pathways[index].archivedAt = nil
        scheduleSave()
    }

    func delete(_ id: Pathway.ID) {
        guard let index = pathways.firstIndex(where: { $0.id == id }) else { return }
        let gone = pathways.remove(at: index)
        retiredReps += gone.lifetimeReps
        for (day, count) in gone.repLog {
            retiredRepLog[day, default: 0] += count
        }
        scheduleSave()
    }
}
