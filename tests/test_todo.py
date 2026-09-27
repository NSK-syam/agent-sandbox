import pytest

from app.todo import TodoList


def test_add_assigns_incrementing_ids():
    todos = TodoList()
    assert todos.add("a").id == 1
    assert todos.add("b").id == 2


def test_add_rejects_blank_title():
    with pytest.raises(ValueError):
        TodoList().add("   ")


def test_complete_and_pending():
    todos = TodoList()
    first = todos.add("a")
    todos.add("b")
    todos.complete(first.id)
    assert [t.title for t in todos.pending()] == ["b"]


def test_remove_unknown_id_raises():
    with pytest.raises(KeyError):
        TodoList().remove(42)


def test_rename_updates_title():
    todos = TodoList()
    task = todos.add("a")
    renamed = todos.rename(task.id, "b")
    assert renamed.title == "b"
    assert todos.all()[0].title == "b"


def test_rename_rejects_blank_title():
    todos = TodoList()
    task = todos.add("a")
    with pytest.raises(ValueError):
        todos.rename(task.id, "   ")


def test_rename_unknown_id_raises():
    with pytest.raises(KeyError):
        TodoList().rename(42, "b")


def test_clear_completed_removes_done_tasks_and_returns_count():
    todos = TodoList()
    first = todos.add("a")
    second = todos.add("b")
    todos.add("c")
    todos.complete(first.id)
    todos.complete(second.id)

    removed = todos.clear_completed()

    assert removed == 2
    assert [t.title for t in todos.all()] == ["c"]


def test_clear_completed_with_no_done_tasks_returns_zero():
    todos = TodoList()
    todos.add("a")

    assert todos.clear_completed() == 0
    assert len(todos.all()) == 1
