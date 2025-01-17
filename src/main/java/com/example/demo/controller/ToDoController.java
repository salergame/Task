package com.example.demo.controller;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.example.demo.model.ToDoItem;

@Controller
@RequestMapping("/")
public class ToDoController {
    private final List<ToDoItem> tasks = new ArrayList<>();

    @GetMapping
    public String index(Model model) {
        model.addAttribute("tasks", tasks);
        return "index";
    }

    @PostMapping("/add")
    public String addTask(@RequestParam String title) {
        tasks.add(new ToDoItem(title, false));
        return "redirect:/";
    }

    @PostMapping("/toggle")
    public String toggleTask(@RequestParam int index) {
        ToDoItem task = tasks.get(index);
        task.setCompleted(!task.isCompleted());
        return "redirect:/";
    }
}
