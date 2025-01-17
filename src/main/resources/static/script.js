// JavaScript для управления списком дел
document.addEventListener('DOMContentLoaded', () => {
    const taskForm = document.querySelector('form[action="/add"]');
    const taskList = document.querySelector('ul');

    // Добавление новой задачи
    taskForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        const formData = new FormData(taskForm);
        const response = await fetch('/add', {
            method: 'POST',
            body: formData,
        });

        if (response.ok) {
            const newTask = await response.json();
            addTaskToDOM(newTask);
            taskForm.reset();
        } else {
            alert('Ошибка добавления задачи');
        }
    });

    // Переключение статуса задачи (выполнена/невыполнена)
    taskList.addEventListener('click', async (event) => {
        if (event.target.tagName === 'BUTTON') {
            const form = event.target.closest('form');
            const formData = new FormData(form);

            const response = await fetch('/toggle', {
                method: 'POST',
                body: formData,
            });

            if (response.ok) {
                const updatedTask = await response.json();
                updateTaskInDOM(form, updatedTask);
            } else {
                alert('Ошибка обновления задачи');
            }
        }
    });

    // Функция для добавления задачи в DOM
    function addTaskToDOM(task) {
        const li = document.createElement('li');
        li.innerHTML = `
            <form action="/toggle" method="post" style="${task.completed ? 'text-decoration: line-through;' : ''}">
                <input type="hidden" name="index" value="${task.index}">
                <span>${task.title}</span>
                <button type="submit">${task.completed ? 'Undo' : 'Complete'}</button>
            </form>
        `;
        taskList.appendChild(li);
    }

    // Функция для обновления задачи в DOM
    function updateTaskInDOM(form, task) {
        const span = form.querySelector('span');
        const button = form.querySelector('button');
        form.style.textDecoration = task.completed ? 'line-through' : '';
        span.textContent = task.title;
        button.textContent = task.completed ? 'Undo' : 'Complete';
    }
});
