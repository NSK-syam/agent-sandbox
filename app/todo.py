"""A tiny in-memory todo list. Deliberately small so agents have something real to extend."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Task:
    id: int
    title: str
    done: bool = False


@dataclass
class TodoList:
    _tasks: dict[int, Task] = field(default_factory=dict)
    _next_id: int = 1

    def add(self, title: str) -> Task:
        title = title.strip()
        if not title:
            raise ValueError("title must not be empty")
        task = Task(id=self._next_id, title=title)
        self._tasks[task.id] = task
        self._next_id += 1
        return task

    def complete(self, task_id: int) -> Task:
        task = self._get(task_id)
        task.done = True
        return task

    def remove(self, task_id: int) -> None:
        self._get(task_id)
        del self._tasks[task_id]

    def all(self) -> list[Task]:
        return list(self._tasks.values())

    def pending(self) -> list[Task]:
        return [t for t in self._tasks.values() if not t.done]

    def _get(self, task_id: int) -> Task:
        try:
            return self._tasks[task_id]
        except KeyError:
            raise KeyError(f"no task with id {task_id}") from None
