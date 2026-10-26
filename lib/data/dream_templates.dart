import 'package:flutter/material.dart';

class DreamTemplate {
  final String title;
  final int color;
  final IconData icon;
  final String socialProof;
  final List<Map<String, dynamic>> steps;

  const DreamTemplate({
    required this.title,
    required this.color,
    required this.icon,
    required this.socialProof,
    required this.steps,
  });
}

final List<DreamTemplate> dreamTemplates = [
  const DreamTemplate(
    title: "Run a Marathon",
    color: 0xFFE91E63,
    icon: Icons.fitness_center_rounded,
    socialProof: "128 people working on this",
    steps: [
      {"title": "Get running shoes", "isCompleted": false},
      {"title": "Run 5km without stopping", "isCompleted": false},
      {"title": "Complete a half marathon", "isCompleted": false},
      {"title": "Register for a marathon", "isCompleted": false},
      {"title": "Finish the race!", "isCompleted": false},
    ],
  ),
  const DreamTemplate(
    title: "Travel the World",
    color: 0xFF2196F3,
    icon: Icons.flight_takeoff_rounded,
    socialProof: "450 people working on this",
    steps: [
      {"title": "Choose 5 bucket list countries", "isCompleted": false},
      {"title": "Apply for necessary visas", "isCompleted": false},
      {"title": "Book first one-way ticket", "isCompleted": false},
      {"title": "Set up a travel blog/vlog", "isCompleted": false},
      {"title": "Depart on the big journey", "isCompleted": false},
    ],
  ),
  const DreamTemplate(
    title: "Launch an App",
    color: 0xFF009688,
    icon: Icons.work_rounded,
    socialProof: "89 developers working on this",
    steps: [
      {"title": "Sketch the core features", "isCompleted": false},
      {"title": "Set up the coding environment", "isCompleted": false},
      {"title": "Build the first working prototype", "isCompleted": false},
      {"title": "Beta test with 5 friends", "isCompleted": false},
      {"title": "Publish to the App Store", "isCompleted": false},
    ],
  ),
  const DreamTemplate(
    title: "Write a Novel",
    color: 0xFF9C27B0,
    icon: Icons.palette_rounded,
    socialProof: "215 writers working on this",
    steps: [
      {"title": "Outline the plot and characters", "isCompleted": false},
      {"title": "Write the first chapter", "isCompleted": false},
      {"title": "Reach 10,000 words", "isCompleted": false},
      {"title": "Complete the first draft", "isCompleted": false},
      {"title": "Send to a proofreader", "isCompleted": false},
    ],
  ),
];
