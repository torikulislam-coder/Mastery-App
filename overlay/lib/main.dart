import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kOrange = Color(0xFFFF6224);
const kInk = Color(0xFF111111);
const kMuted = Color(0xFF6B7280);
const kSurface = Color(0xFFF3F4F6);
const kLine = Color(0xFFE5E7EB);
const kSite = 'https://mastery.com.bd';
const kPhone = '+8801911564664';

Future<void> openUrl(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

const _digits = '০১২৩৪৫৬৭৮৯';

String bn(Object n) => n.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? c : _digits[d];
    }).join();

String taka(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '৳${bn(b)}';
}

class Course {
  const Course(this.title, this.instructor, this.id, this.price, this.live,
      [this.oldPrice]);
  final String title;
  final String instructor;
  final String id;
  final int price;
  final bool live;
  final int? oldPrice;

  String get url => '$kSite/courses/$id';
  int? get discount =>
      oldPrice == null ? null : (100 - price * 100 / oldPrice!).round();
}

// mastery.com.bd থেকে নেওয়া কোর্স তালিকা। পরে API সংযোগ হলে এখানে লাইভ ডেটা আসবে।
const courses = <Course>[
  Course('MS Excel Professional ৭ দিনের লাইভ ট্রেনিং', 'MD. Sami',
      '627245c6-e617-4707-921f-89ea1b32af1c', 199, true),
  Course('HR & Admin Management with Excel', 'Mastery Admin',
      '7a0a7666-8d61-49d0-9401-5025cb2ef07c', 4990, true),
  Course('MIS & Business Reporting', 'Mastery Admin',
      '55c31a55-60ec-49b3-ba47-ae6c2e42e90c', 12000, true),
  Course('Finance & Banking Professional', 'Mastery Admin',
      'eb4494ca-23f6-4a48-992b-905a61817b25', 7000, true),
  Course('Sales & Marketing Management', 'Mastery Admin',
      '91e39d86-5483-4f41-870c-7747ede84260', 4900, true),
  Course('ঘরে বসে Spoken English', 'MD. Tuhin',
      '8117a513-f3ee-4a51-8c3c-f293021319ad', 2999, true, 8790),
  Course('SQL Live Boot Camp', 'Imran Hossain',
      'e507d8ed-6aa0-4898-a255-2c31cd389bfe', 4900, true, 8090),
  Course('MS Excel Mastery with AI', 'Imran Hossain',
      'babfe8bf-41f4-4db9-8d5d-4967540c5208', 1299, false, 2600),
  Course('Power BI Data Analysis', 'Imran Hossain',
      'b2a393f9-8bcb-4694-a5ba-6b1c7d4db1c5', 4990, false, 8000),
  Course('MS PowerPoint Genius', 'Imran Hossain',
      '7a80e28c-23d4-4ac6-9a30-ab17e19f49b5', 999, false, 1750),
  Course('কুরআন শিক্ষা কোর্স', 'Mastery Admin',
      'a7922cca-ded2-4eb9-ba5d-5a08788fe848', 599, false, 4999),
  Course('নামাজ শিক্ষা কোর্স', 'Mastery Admin',
      'd4fe192a-616e-4941-a096-ebaeef3d992b', 599, false, 5000),
];

void main() => runApp(const MasteryApp());

class MasteryApp extends StatelessWidget {
  const MasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mastery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kOrange,
          primary: kOrange,
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onSeeAll: () => setState(() => i = 1)),
      const CoursesPage(),
      const LearningPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: IndexedStack(index: i, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0x26FF6224),
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: kOrange),
              label: 'হোম'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: kOrange),
              label: 'কোর্স'),
          NavigationDestination(
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle, color: kOrange),
              label: 'আমার শেখা'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: kOrange),
              label: 'প্রোফাইল'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final hero = courses.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Image.asset('assets/logo.png', height: 34),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: () => openUrl('tel:$kPhone'),
            icon: const Icon(Icons.call_outlined),
          ),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: kOrange, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('লাইভ ব্যাচ',
                  style: TextStyle(
                      color: kOrange, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            const Text('কর্পোরেট জবের জন্য MS Excel শিখুন ৭ দিনের লাইভ ট্রেনিংয়ে',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3)),
            const SizedBox(height: 8),
            const Text(
                'রিয়েল-লাইফ প্রজেক্ট, পিভট টেবিল ও অটোমেটেড ড্যাশবোর্ড শিখুন ইন্ডাস্ট্রি এক্সপার্টের সাথে।',
                style: TextStyle(color: Colors.white, height: 1.45)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: kOrange),
              onPressed: () => openUrl(hero.url),
              child: Text('রেজিস্ট্রেশন করুন (${taka(hero.price)})'),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        const Text(
            'প্র্যাকটিস ফাইল, লাইভ সাপোর্ট ও সার্টিফিকেটসহ। ২০,০০০+ স্টুডেন্ট বিভিন্ন প্রতিষ্ঠানে কর্মরত।',
            style: TextStyle(color: kMuted, fontSize: 13, height: 1.4)),
        const SizedBox(height: 22),
        Row(children: [
          const Text('জনপ্রিয় কোর্স',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(onPressed: onSeeAll, child: const Text('সব দেখুন')),
        ]),
        const SizedBox(height: 6),
        ...courses.skip(1).take(4).map((c) => CourseTile(c)),
      ],
    );
  }
}

class CourseTile extends StatelessWidget {
  const CourseTile(this.c, {super.key});
  final Course c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kLine),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showCourse(context, c),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: c.live ? kOrange : kSurface,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(c.live ? Icons.sensors : Icons.play_arrow_rounded,
                    color: c.live ? Colors.white : kInk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(c.instructor,
                          style: const TextStyle(color: kMuted, fontSize: 12.5)),
                    ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(taka(c.price),
                    style: const TextStyle(
                        color: kOrange, fontWeight: FontWeight.w800)),
                if (c.oldPrice != null)
                  Text(taka(c.oldPrice!),
                      style: const TextStyle(
                          color: kMuted,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

void showCourse(BuildContext context, Course c) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.live ? 'লাইভ কোর্স' : 'রেকর্ডেড কোর্স',
              style: const TextStyle(
                  color: kOrange, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(c.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('ইনস্ট্রাক্টর: ${c.instructor}',
              style: const TextStyle(color: kMuted)),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(taka(c.price),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            if (c.oldPrice != null) ...[
              const SizedBox(width: 10),
              Text(taka(c.oldPrice!),
                  style: const TextStyle(
                      color: kMuted, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 10),
              Text('${bn(c.discount!)}% ছাড়',
                  style: const TextStyle(
                      color: kOrange, fontWeight: FontWeight.w700)),
            ],
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => openUrl(c.url),
              child: const Text('এনরোল করুন'),
            ),
          ),
        ],
      ),
    ),
  );
}

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  int filter = 0; // 0 সব, 1 লাইভ, 2 রেকর্ডেড
  String q = '';

  @override
  Widget build(BuildContext context) {
    final needle = q.toLowerCase();
    final list = courses
        .where((c) =>
            (filter == 0 || (filter == 1) == c.live) &&
            (needle.isEmpty ||
                c.title.toLowerCase().contains(needle) ||
                c.instructor.toLowerCase().contains(needle)))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('কোর্স',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(
            hintText: 'কোর্স বা ইনস্ট্রাক্টর খুঁজুন',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: kSurface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
              selectedBackgroundColor: kOrange,
              selectedForegroundColor: Colors.white),
          segments: const <ButtonSegment<int>>[
            ButtonSegment<int>(value: 0, label: Text('সব')),
            ButtonSegment<int>(value: 1, label: Text('লাইভ')),
            ButtonSegment<int>(value: 2, label: Text('রেকর্ডেড')),
          ],
          selected: {filter},
          onSelectionChanged: (s) => setState(() => filter = s.first),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('কোনো কোর্স পাওয়া যায়নি। অন্য নাম দিয়ে খুঁজুন।',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted)),
          ),
        ...list.map((c) => CourseTile(c)),
      ],
    );
  }
}

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.play_circle_outline, size: 56, color: kOrange),
          const SizedBox(height: 14),
          const Text('আপনার কোর্স দেখুন',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'এনরোল করা কোর্স, প্র্যাকটিস ফাইল ও সার্টিফিকেট দেখতে Mastery অ্যাকাউন্টে লগইন করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, height: 1.45)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => openUrl('$kSite/login'),
            child: const Text('লগইন করুন'),
          ),
        ]),
      ),
    );
  }
}

class LinkTile extends StatelessWidget {
  const LinkTile(this.icon, this.label, this.url, {super.key});
  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: kOrange),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: kMuted),
      onTap: () => openUrl(url),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset('assets/logo.png', height: 44),
        ),
        const SizedBox(height: 6),
        const Text('Learn, Practice, Succeed',
            style: TextStyle(color: kMuted)),
        const SizedBox(height: 18),
        LinkTile(Icons.call_outlined, 'সাপোর্টে কল করুন (০১৯১১-৫৬৪৬৬৪)',
            'tel:$kPhone'),
        const Divider(height: 1, color: kLine),
        const LinkTile(Icons.local_offer_outlined, 'সব অফার', '$kSite/offers'),
        const Divider(height: 1, color: kLine),
        const LinkTile(
            Icons.groups_outlined, 'ইনস্ট্রাক্টর', '$kSite/instructors'),
        const Divider(height: 1, color: kLine),
        const LinkTile(Icons.verified_outlined, 'সার্টিফিকেট যাচাই',
            '$kSite/verify-certificate'),
        const Divider(height: 1, color: kLine),
        const LinkTile(
            Icons.route_outlined, 'Career Journey', '$kSite/career-journey'),
        const Divider(height: 1, color: kLine),
        const LinkTile(Icons.facebook, 'Facebook পেজ',
            'https://www.facebook.com/mastery.com.bd'),
        const Divider(height: 1, color: kLine),
        const LinkTile(Icons.policy_outlined, 'রিফান্ড পলিসি',
            '$kSite/refund-policy'),
        const Divider(height: 1, color: kLine),
        const LinkTile(Icons.lock_outline, 'গোপনীয়তা নীতি',
            '$kSite/privacy-policy'),
        const SizedBox(height: 24),
        const Text('© ২০২৬ Mastery Corporation',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 12)),
      ],
    );
  }
}
