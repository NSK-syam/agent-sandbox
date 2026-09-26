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
