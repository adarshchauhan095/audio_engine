#include "EventScheduler.h"

void EventScheduler::clear() {
  std::lock_guard<std::mutex> lock(mutex_);
  events_.clear();
}

void EventScheduler::scheduleDefaultSequence() {
  std::lock_guard<std::mutex> lock(mutex_);
  events_.clear();
  events_.push_back({0.00, 440.0});
  events_.push_back({0.25, 550.0});
  events_.push_back({0.50, 660.0});
  events_.push_back({0.75, 440.0});
}

void EventScheduler::startSession() {
  sessionActive_.store(true, std::memory_order_relaxed);
}

void EventScheduler::stopSession() {
  sessionActive_.store(false, std::memory_order_relaxed);
}

bool EventScheduler::isSessionActive() const {
  return sessionActive_.load(std::memory_order_relaxed);
}

std::vector<ScheduledEvent> EventScheduler::snapshot() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return events_;
}

