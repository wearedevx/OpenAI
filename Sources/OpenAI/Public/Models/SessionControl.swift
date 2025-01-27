//
//  SessionControl.swift
//  OpenAI
//
//  Created by Gaël Philippe on 27/01/2025.
//

public class SessionControl<T>
    where T: Codable
{
    private var session: StreamingSession<T>?

    public init() {}

    func setSession(_ session: StreamingSession<T>) {
        self.session = session
    }

    public func cancel() {
        session?.cancel()
        session = nil
    }
}
