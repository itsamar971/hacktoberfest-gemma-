class BlogPost {
  final String id;
  final String title;
  final String excerpt;
  final String category;
  final int readTimeMinutes;
  final String imageUrl;
  final String content;
  final BlogSurvey? survey;

  BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.readTimeMinutes,
    required this.imageUrl,
    required this.content,
    this.survey,
  });
}

class BlogSurvey {
  final String question;
  final List<String> options;

  BlogSurvey({
    required this.question,
    required this.options,
  });
}

// Curated blog posts for ambitious women
List<BlogPost> getBlogPosts() {
  return [
    BlogPost(
      id: '1',
      title: 'The Power of Micro-Goals',
      excerpt: 'Why breaking down your dreams into tiny steps is the secret to unstoppable progress.',
      category: 'Productivity',
      readTimeMinutes: 3,
      imageUrl: '🎯',
      content: '''
# The Power of Micro-Goals

Big dreams can feel overwhelming. The gap between where you are and where you want to be seems impossible to cross. But here's the secret that successful women know: **you don't need to leap across the gap—you need to build a bridge, one tiny step at a time.**

## Why Micro-Goals Work

Our brains are wired to resist big, scary changes. But when you break a massive goal into micro-goals—actions so small they feel almost silly—you bypass that resistance entirely.

**Example:** Want to write a book? Don't start with "write a book." Start with "write one sentence today."

## The 2-Minute Rule

If a micro-goal takes less than 2 minutes, you have no excuse not to do it. And once you start, momentum takes over.

**Your Turn:** What's one dream you've been putting off? What's the smallest possible first step you could take today—something that takes less than 2 minutes?

The magic isn't in the size of the step. It's in the consistency of taking it.
''',
      survey: BlogSurvey(
        question: 'What\'s your biggest challenge with goal-setting?',
        options: [
          'Getting started',
          'Staying consistent',
          'Knowing what to prioritize',
          'Overcoming self-doubt',
        ],
      ),
    ),
    BlogPost(
      id: '2',
      title: 'Redefining Success on Your Terms',
      excerpt: 'Stop chasing someone else\'s definition of success. Here\'s how to create your own.',
      category: 'Mindset',
      readTimeMinutes: 4,
      imageUrl: '👑',
      content: '''
# Redefining Success on Your Terms

Society tells us what success should look like: the corner office, the six-figure salary, the perfect Instagram feed. But what if none of that actually makes you happy?

## The Success Trap

We spend years climbing ladders only to realize they're leaning against the wrong wall. The promotion you worked so hard for leaves you exhausted. The lifestyle you curated feels empty.

**Here's the truth:** Success isn't one-size-fits-all. Your version of success might look completely different from mine—and that's not just okay, it's essential.

## Questions to Ask Yourself

1. **What energizes me?** Not what impresses others, but what genuinely lights you up.
2. **What would I do if I knew I couldn't fail?** Remove the fear and see what remains.
3. **What does my ideal Tuesday look like?** Forget the highlight reel—what does a regular day in your dream life actually involve?

## Permission to Pivot

You're allowed to change your mind. The goals you set at 22 don't have to be the same at 32. Growth means evolving, not staying stuck in old dreams that no longer fit.

**Your success is yours to define.** Start designing it today.
''',
      survey: BlogSurvey(
        question: 'What does success mean to you right now?',
        options: [
          'Financial freedom',
          'Work-life balance',
          'Making an impact',
          'Personal fulfillment',
        ],
      ),
    ),
    BlogPost(
      id: '3',
      title: 'The Art of Saying No',
      excerpt: 'Every "yes" to something unimportant is a "no" to your dreams. Master the art of boundaries.',
      category: 'Boundaries',
      readTimeMinutes: 3,
      imageUrl: '🛡️',
      content: '''
# The Art of Saying No

As ambitious women, we're taught to be helpful, accommodating, and always available. But here's what nobody tells you: **every "yes" to something that doesn't serve you is a "no" to something that does.**

## The Cost of Yes

That committee you joined to be nice? It's stealing time from your side business. The friend who only calls to complain? She's draining energy you need for your own growth.

Your time and energy are finite resources. Treat them like the precious commodities they are.

## How to Say No Gracefully

You don't need elaborate excuses. Try these:
- "I appreciate you thinking of me, but I can't commit to that right now."
- "That sounds great, but it's not aligned with my priorities this season."
- "I'm going to pass, but thank you for the opportunity."

Notice: No apologies. No over-explaining. Just a clear, kind boundary.

## What to Say Yes To

Before saying yes to anything, ask: **Does this move me closer to my goals or further away?**

If it's not a clear yes, it's a no.

**Your dreams are waiting.** Stop giving your best energy to everything else.
''',
      survey: BlogSurvey(
        question: 'What\'s hardest about saying no for you?',
        options: [
          'Fear of disappointing others',
          'Guilt',
          'FOMO (fear of missing out)',
          'Worrying about being seen as difficult',
        ],
      ),
    ),
    BlogPost(
      id: '4',
      title: 'Morning Rituals That Actually Work',
      excerpt: 'Forget the 5 AM club. Here\'s how to design a morning routine that fits your real life.',
      category: 'Lifestyle',
      readTimeMinutes: 4,
      imageUrl: '☀️',
      content: '''
# Morning Rituals That Actually Work

The internet is full of "perfect morning routines" that involve waking up at 5 AM, meditating for an hour, journaling, working out, and making a green smoothie—all before 7 AM.

**Reality check:** Most of us hit snooze, rush through getting ready, and grab coffee on the way out the door.

## The Truth About Morning Routines

The best morning routine isn't the one that looks impressive on Instagram. It's the one you'll actually do.

## Start Small

Pick ONE thing that makes you feel good and do it every morning:
- 5 minutes of stretching
- Writing 3 things you're grateful for
- Drinking a full glass of water
- Reading one page of something inspiring

That's it. One thing. Master that before adding more.

## The Power of Consistency

A simple routine you do every day beats an elaborate one you do once a month. The magic is in the repetition, not the complexity.

## Make It Yours

Your morning routine should reflect your goals and energy:
- **Creative?** Start with 10 minutes of free writing.
- **Anxious?** Try breathwork or meditation.
- **Goal-oriented?** Review your top 3 priorities for the day.

**There's no one right way.** Design a morning that sets YOU up for success.
''',
      survey: BlogSurvey(
        question: 'What time do you typically wake up?',
        options: [
          'Before 6 AM',
          '6-7 AM',
          '7-8 AM',
          'After 8 AM',
        ],
      ),
    ),
    BlogPost(
      id: '5',
      title: 'Building Confidence from the Inside Out',
      excerpt: 'Confidence isn\'t something you\'re born with. It\'s a skill you build, one action at a time.',
      category: 'Personal Growth',
      readTimeMinutes: 5,
      imageUrl: '💪',
      content: '''
# Building Confidence from the Inside Out

We often think confidence is something other people have and we don't. But here's the secret: **confidence isn't a personality trait—it's a skill you build through action.**

## The Confidence-Action Loop

Most people wait to feel confident before taking action. But it works the opposite way:
1. You take action (even when scared)
2. You survive it
3. Your brain updates its belief about what you're capable of
4. You feel more confident next time

**Confidence is the result of action, not the prerequisite.**

## Start With Evidence

Your brain believes what you show it. Start collecting evidence of your capabilities:
- Keep a "wins" journal
- Save positive feedback
- Track your progress, no matter how small

When self-doubt creeps in, you'll have proof to counter it.

## The Power of "Yet"

Replace "I can't do this" with "I can't do this *yet*."

That one word transforms failure into a temporary state instead of a permanent identity.

## Fake It Till You Become It

Body language shapes how you feel. Stand tall, make eye contact, take up space. Your brain will follow your body's lead.

**You don't need to feel confident to act confident.** Act first, and the feeling will follow.
''',
      survey: BlogSurvey(
        question: 'Where do you most want to build confidence?',
        options: [
          'Career/work',
          'Relationships',
          'Personal projects',
          'Social situations',
        ],
      ),
    ),
    BlogPost(
      id: '6',
      title: 'The Comparison Trap',
      excerpt: 'Social media makes it easy to compare your behind-the-scenes to everyone else\'s highlight reel.',
      category: 'Mindset',
      readTimeMinutes: 3,
      imageUrl: '📱',
      content: '''
# The Comparison Trap

You're scrolling Instagram. Everyone seems to have it together—the dream job, the perfect relationship, the exotic vacation, the flawless skin. Meanwhile, you're in sweatpants eating cereal for dinner.

**Welcome to the comparison trap.**

## The Highlight Reel vs. Reality

Social media is everyone's curated highlight reel. You're comparing your messy, unfiltered reality to their carefully edited best moments.

It's like comparing your blooper reel to their movie trailer. Of course you feel like you're falling behind.

## The Cost of Comparison

Every minute you spend comparing yourself to others is a minute stolen from building your own life. Comparison is a creativity killer, a joy thief, and a dream destroyer.

## Break Free

1. **Unfollow ruthlessly.** If someone's feed makes you feel bad, unfollow. Your mental health matters more than being polite.

2. **Celebrate others without diminishing yourself.** Someone else's success doesn't make you a failure.

3. **Run your own race.** The only person you should compare yourself to is who you were yesterday.

## Your Journey Is Yours

There is no timeline. There is no "should be here by now." You're exactly where you need to be.

**Focus on your path, not their pace.**
''',
      survey: BlogSurvey(
        question: 'How often do you find yourself comparing to others?',
        options: [
          'Daily',
          'A few times a week',
          'Occasionally',
          'Rarely',
        ],
      ),
    ),
  ];
}
