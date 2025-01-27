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

    init() {}

    func setSession(_ session: StreamingSession<T>) {
        self.session = session
    }

    func cancel() {
        session?.cancel()
        session = nil
    }
}
