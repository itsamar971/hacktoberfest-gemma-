import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';
import 'achievement_completion_page.dart';
import '../services/gemini_service.dart';
import '../utils/pro_modal_utils.dart';
import 'package:lottie/lottie.dart';

import '../data/dream_templates.dart';

class AddDreamScreen extends StatefulWidget {
  final DreamTemplate? template;
  const AddDreamScreen({super.key, this.template});

  @override
  State<AddDreamScreen> createState() => _AddDreamScreenState();
}

class _AddDreamScreenState extends State<AddDreamScreen> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  late int _selectedColor;
  late int _selectedIcon;
  DreamTemplate? _selectedTemplate;
  
  bool _generateWithAi = false;
  int _aiDurationDays = 7;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.template?.title ?? '');
    _selectedColor = widget.template?.color ?? 0xFFE91E63;
    _selectedIcon = widget.template?.icon.codePoint ?? 59688;
    _selectedTemplate = widget.template;
  }

  final List<int> _colors = [
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF2196F3, // Blue
    0xFF009688, // Teal
    0xFFFFC107, // Amber
    0xFFFF5722, // Orange
  ];

  final List<IconData> _icons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.flight_takeoff_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.music_note_rounded,
    Icons.fitness_center_rounded,
    Icons.palette_rounded,
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("New Dream"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Need an idea?",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dreamTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final template = dreamTemplates[index];
                    return ActionChip(
                      avatar: Icon(template.icon, size: 16, color: Color(template.color)),
                      label: Text(template.title),
                      onPressed: () {
                        setState(() {
                          _controller.text = template.title;
                          _selectedColor = template.color;
                          _selectedIcon = template.icon.codePoint;
                          _selectedTemplate = template;
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Color(template.color).withOpacity(0.05),
                      side: BorderSide(color: Color(template.color).withOpacity(0.2)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "What's your big dream?",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                autofocus: true,
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: "e.g. Write a novel...",
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a dream';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Theme Selector
              Text("Pick a Vibe", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final color = _colors[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: _selectedColor == color 
                             ? Border.all(color: Colors.black, width: 3) 
                             : null,
                        ),
                        child: _selectedColor == color 
                             ? const Icon(Icons.check, color: Colors.white) 
                             : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
               SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final icon = _icons[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon.codePoint),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _selectedIcon == icon.codePoint 
                             ? Color(_selectedColor).withOpacity(0.2) 
                             : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: _selectedIcon == icon.codePoint 
                             ? Border.all(color: Color(_selectedColor), width: 2) 
                             : null,
                        ),
                        child: Icon(icon, color: _selectedIcon == icon.codePoint ? Color(_selectedColor) : Colors.grey),
                      ),
                    );
                  },
                ),
              ),



              const SizedBox(height: 32),
              
              // AI Generation Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _generateWithAi,
                      onChanged: (val) {
                         setState(() {
                           _generateWithAi = val;
                           // Clear manual date if AI is selected (AI sets duration)
                           if (val) _selectedDate = null;
                         });
                      },
                      title: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 20),
                          SizedBox(width: 12),
                          Text("Generate Plan with AI", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      subtitle: const Text("Create daily micro-actions automatically"),
                      activeColor: Colors.purple,
                    ),
                    
                    if (_generateWithAi) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Text("Duration:", style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[900] 
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey[800]! 
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  dropdownColor: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey[900] 
                                      : Colors.white,
                                  value: _aiDurationDays,
                                  items: const [
                                    DropdownMenuItem(value: 7, child: Text("7 Days (Kickstarter)")),
                                    DropdownMenuItem(value: 14, child: Text("14 Days (Sprint)")),
                                    DropdownMenuItem(value: 30, child: Text("30 Days (Challenge)")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _aiDurationDays = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Date Picker (Disable if AI is on)
              Opacity(
                opacity: _generateWithAi ? 0.5 : 1.0,
                child: AbsorbPointer(
                  absorbing: _generateWithAi,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Target Date (Optional)", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: Color(_selectedColor)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null 
                           ? "Set a deadline" 
                           : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        style: TextStyle(
                            fontSize: 16, 
                            color: _selectedDate == null 
                                ? Colors.grey 
                                : Theme.of(context).colorScheme.onSurface
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_selectedColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isGenerating ? null : _saveDream,
                  child: _isGenerating 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Plan My Dream!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveDream() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isGenerating = true);
      
      // Show loading bottom sheet if AI is enabled
      if (_generateWithAi && mounted) {
        _showAiLoadingBottomSheet(context);
      }

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        // All users have unlimited dreams enabled

        List<Map<String, dynamic>>? aiSteps;

        // Call Gemini / Gemma AI if enabled
        if (_generateWithAi) {
           try {
             aiSteps = await GeminiService().generateDreamTasks(
               _controller.text,
               days: _aiDurationDays,
             );
           } catch (e) {
             debugPrint("Gemini AI Generation Failed: $e");
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("AI Generation failed: $e. Creating empty dream instead."))
                );
             }
           }
        }

        final newAchievements = await appState.addDream(
            _controller.text, 
            deadline: _generateWithAi 
                ? DateTime.now().add(Duration(days: _aiDurationDays)) 
                : _selectedDate,
            themeColor: _selectedColor,
            themeIcon: _selectedIcon,
            initialSteps: aiSteps ?? _selectedTemplate?.steps, 
        );
        
        if (mounted) {
          // If loading sheet was shown, pop it
          if (_generateWithAi) {
            Navigator.pop(context);
          }
          
          Navigator.pop(context);
          
          if (newAchievements.isNotEmpty) {
             for (final achievement in newAchievements) {
                 Navigator.of(context).push(
                   MaterialPageRoute(
                     builder: (context) => AchievementCompletionPage(achievement: achievement),
                     fullscreenDialog: true,
                   ),
                 );
                if (newAchievements.length > 1) {
                  await Future.delayed(const Duration(seconds: 2));
                }
             }
          }
        }
      } catch (e) {
        if (mounted && _generateWithAi) {
          Navigator.pop(context);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"))
          );
        }
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    }
  }

  void _showAiLoadingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiLoadingBottomSheetContent(selectedColor: _selectedColor),
    );
  }
}

class _AiLoadingBottomSheetContent extends StatefulWidget {
  final int selectedColor;
  const _AiLoadingBottomSheetContent({required this.selectedColor});

  @override
  State<_AiLoadingBottomSheetContent> createState() => _AiLoadingBottomSheetContentState();
}

class _AiLoadingBottomSheetContentState extends State<_AiLoadingBottomSheetContent> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            width: 200,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.transparent 
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Lottie.asset(
                'assets/images/loading.json',
                controller: _controller,
                onLoaded: (composition) {
                  // Set speed to 6x by shortening the duration
                  _controller.duration = Duration(milliseconds: (composition.duration.inMilliseconds / 6.0).round());
                  _controller.repeat();
                },
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(
                      const ['**'],
                      value: Color(widget.selectedColor),
                    ),
                  ],
                ),
                frameRate: FrameRate.composition,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color(widget.selectedColor),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Dreaming up your journey...",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "AI is mapping out your path and breaking it down into actionable daily steps.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
