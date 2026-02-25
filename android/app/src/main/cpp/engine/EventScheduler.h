#pragma once

#include <atomic>
#include <mutex>
#include <vector>

/// Represents a future parameter update.
struct ScheduledEvent {
  double timeSeconds = 0.0;
  double targetFrequencyHz = 440.0;
};

/// Stores timed events for future session-driven automation.
///
/// This module is intentionally passive for now: events can be configured,
/// but they are not consumed in the render callback yet.
class EventScheduler {
public:
  void clear();
  void scheduleDefaultSequence();

  void startSession();
  void stopSession();
  bool isSessionActive() const;

  std::vector<ScheduledEvent> snapshot() const;

private:
  mutable std::mutex mutex_;
  std::vector<ScheduledEvent> events_;
  std::atomic<bool> sessionActive_{false};
};

