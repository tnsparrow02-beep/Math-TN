import 'package:flutter/material.dart';

/// Ready-to-use question (1 correct answer + 2 wrong answers).
class LibQuestion {
  final String text;
  final String correct;
  final String wrong1;
  final String wrong2;
  const LibQuestion(this.text, this.correct, this.wrong1, this.wrong2);
}

class LibCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<LibQuestion> questions;
  const LibCategory({required this.id, required this.title, required this.icon, required this.color, required this.questions});
}

/// Built-in quiz library: 72 ready questions in 9 categories (Arabic).
const List<LibCategory> kQuizLibrary = [
  LibCategory(
    id: 'numbers',
    title: 'الأعداد والحساب',
    icon: Icons.calculate_rounded,
    color: Color(0xFF3730A3),
    questions: [
      LibQuestion('ما ناتج 125 + 78؟', '203', '193', '213'),
      LibQuestion('ما ناتج 12 × 15؟', '180', '170', '160'),
      LibQuestion('ما ناتج 144 ÷ 12؟', '12', '14', '11'),
      LibQuestion('أي عدد من الأعداد التالية أولي؟', '17', '21', '27'),
      LibQuestion('ما ناتج 7 × 8 − 6؟', '50', '42', '8'),
      LibQuestion('ما هو القاسم المشترك الأكبر للعددين 12 و 18؟', '6', '3', '36'),
      LibQuestion('ما هو المضاعف المشترك الأصغر للعددين 4 و 6؟', '12', '24', '2'),
      LibQuestion('أي عدد من الأعداد التالية يقبل القسمة على 3؟', '123', '124', '125'),
    ],
  ),
  LibCategory(
    id: 'fractions',
    title: 'الكسور والأعداد العشرية',
    icon: Icons.pie_chart_rounded,
    color: Color(0xFFD97706),
    questions: [
      LibQuestion('ما ناتج 1/2 + 1/4؟', '3/4', '2/6', '1/6'),
      LibQuestion('ما ناتج 2/3 × 3/5؟', '2/5', '6/8', '5/8'),
      LibQuestion('اختزل الكسر 12/18', '2/3', '3/4', '4/5'),
      LibQuestion('ما ناتج 0,5 + 0,25؟', '0,75', '0,30', '0,80'),
      LibQuestion('ما ناتج 3,2 × 10؟', '32', '320', '0,32'),
      LibQuestion('أي الكسور التالية هو الأكبر؟', '3/4', '2/3', '1/2'),
      LibQuestion('ما الكتابة العشرية للكسر 1/4؟', '0,25', '0,14', '0,4'),
      LibQuestion('ما ناتج 5/6 − 1/3؟', '1/2', '4/3', '2/3'),
    ],
  ),
  LibCategory(
    id: 'signed',
    title: 'الأعداد النسبية',
    icon: Icons.exposure_rounded,
    color: Color(0xFF0E7490),
    questions: [
      LibQuestion('ما ناتج (−5) + 8؟', '3', '−3', '13'),
      LibQuestion('ما ناتج (−4) × (−3)؟', '12', '−12', '−7'),
      LibQuestion('ما ناتج 6 − 10؟', '−4', '4', '−16'),
      LibQuestion('ما ناتج (−18) ÷ 3؟', '−6', '6', '−15'),
      LibQuestion('أي عدد من الأعداد التالية هو الأصغر؟', '−7', '−2', '0'),
      LibQuestion('ما هو مقابل العدد 9؟', '−9', '9', '1/9'),
      LibQuestion('ما هي القيمة المطلقة للعدد −12؟', '12', '−12', '0'),
      LibQuestion('ما ناتج (−2) + (−7)؟', '−9', '9', '−5'),
    ],
  ),
  LibCategory(
    id: 'powers',
    title: 'القوى والجذور المربعة',
    icon: Icons.superscript_rounded,
    color: Color(0xFF9333EA),
    questions: [
      LibQuestion('ما قيمة 3²؟', '9', '6', '8'),
      LibQuestion('ما قيمة 2³؟', '8', '6', '9'),
      LibQuestion('ما قيمة √49؟', '7', '8', '14'),
      LibQuestion('ما قيمة 10³؟', '1000', '30', '100'),
      LibQuestion('ما قيمة 5⁰؟', '1', '0', '5'),
      LibQuestion('ما ناتج 2² × 2³؟', '32', '16', '64'),
      LibQuestion('ما قيمة √81؟', '9', '8', '27'),
      LibQuestion('أي عدد مما يلي هو مربع كامل؟', '64', '48', '72'),
    ],
  ),
  LibCategory(
    id: 'algebra',
    title: 'الجبر والمعادلات',
    icon: Icons.functions_rounded,
    color: Color(0xFF059669),
    questions: [
      LibQuestion('حلّ المعادلة x + 5 = 12', 'x = 7', 'x = 17', 'x = −7'),
      LibQuestion('حلّ المعادلة 3x = 18', 'x = 6', 'x = 15', 'x = 54'),
      LibQuestion('حلّ المعادلة 2x − 4 = 10', 'x = 7', 'x = 3', 'x = 12'),
      LibQuestion('ما قيمة العبارة 3a + 2 عندما a = 4؟', '14', '24', '9'),
      LibQuestion('انشر العبارة 2(x + 3)', '2x + 6', '2x + 3', 'x + 6'),
      LibQuestion('اختزل العبارة 4x + 3x', '7x', '12x', '7x²'),
      LibQuestion('أي كتابة مما يلي تساوي 6x + 9؟', '3(2x + 3)', '6(x + 9)', '2(3x + 9)'),
      LibQuestion('حلّ المعادلة x/4 = 5', 'x = 20', 'x = 9', 'x = 1,25'),
    ],
  ),
  LibCategory(
    id: 'ratio',
    title: 'التناسب والنسب المئوية',
    icon: Icons.compare_arrows_rounded,
    color: Color(0xFFBE185D),
    questions: [
      LibQuestion('ما هو 10% من 200؟', '20', '2', '100'),
      LibQuestion('ما هو 25% من 80؟', '20', '25', '40'),
      LibQuestion('ثمن سلعة 50 دينارا خُفّض بنسبة 20%. ما الثمن الجديد؟', '40 دينارا', '30 دينارا', '45 دينارا'),
      LibQuestion('ثمن 3 كراسات 6 دنانير. ما ثمن 5 كراسات؟', '10 دنانير', '9 دنانير', '15 دينارا'),
      LibQuestion('ما النسبة المئوية المكافئة للكسر 1/2؟', '50%', '20%', '12%'),
      LibQuestion('سيارة تقطع 120 كم في ساعتين. ما سرعتها؟', '60 كم/س', '240 كم/س', '30 كم/س'),
      LibQuestion('ما قيمة x في التناسب 2/3 = x/9؟', '6', '4', '12'),
      LibQuestion('نجح 18 تلميذا من 24. ما نسبة النجاح؟', '75%', '80%', '66%'),
    ],
  ),
  LibCategory(
    id: 'geometry',
    title: 'الهندسة',
    icon: Icons.change_history_rounded,
    color: Color(0xFF4D7C0F),
    questions: [
      LibQuestion('مجموع قيسي زوايا المثلث يساوي:', '180°', '90°', '360°'),
      LibQuestion('مجموع قيسي زوايا الرباعي يساوي:', '360°', '180°', '270°'),
      LibQuestion('كم عدد محاور تماثل المربع؟', '4', '2', '1'),
      LibQuestion('المثلث الذي أضلاعه الثلاثة متقايسة يسمى:', 'متقايس الأضلاع', 'قائم الزاوية', 'متقايس الضلعين'),
      LibQuestion('مثلث قائم الزاوية طولا ضلعيه القائمين 3 و 4. ما طول وتره؟', '5', '7', '6'),
      LibQuestion('الزاوية التي قيسها 90° تسمى:', 'قائمة', 'حادة', 'منفرجة'),
      LibQuestion('قيس الزاوية المستقيمة هو:', '180°', '90°', '360°'),
      LibQuestion('كم قيس كل زاوية في مثلث متقايس الأضلاع؟', '60°', '45°', '90°'),
    ],
  ),
  LibCategory(
    id: 'measure',
    title: 'القياس والمساحات والحجوم',
    icon: Icons.straighten_rounded,
    color: Color(0xFFB45309),
    questions: [
      LibQuestion('مساحة مستطيل طوله 8 سم وعرضه 5 سم هي:', '40 سم²', '26 سم²', '13 سم²'),
      LibQuestion('محيط مربع طول ضلعه 6 سم هو:', '24 سم', '36 سم', '12 سم'),
      LibQuestion('مساحة مثلث قاعدته 10 سم وارتفاعه 6 سم هي:', '30 سم²', '60 سم²', '16 سم²'),
      LibQuestion('محيط دائرة شعاعها r هو:', '2πr', 'πr²', 'πr'),
      LibQuestion('مساحة قرص شعاعه r هي:', 'πr²', '2πr', '2r²'),
      LibQuestion('حجم مكعب طول حرفه 3 سم هو:', '27 سم³', '9 سم³', '18 سم³'),
      LibQuestion('1 متر يساوي:', '100 سم', '10 سم', '1000 سم'),
      LibQuestion('1 لتر يساوي:', '1000 مل', '100 مل', '10 مل'),
    ],
  ),
  LibCategory(
    id: 'stats',
    title: 'الإحصاء والاحتمالات',
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF3730A3),
    questions: [
      LibQuestion('ما هو المعدل (المتوسط الحسابي) للأعداد 4 و 6 و 8؟', '6', '5', '8'),
      LibQuestion('ما هو منوال السلسلة 2 ، 3 ، 3 ، 5 ، 7؟', '3', '5', '2'),
      LibQuestion('ما هو وسيط السلسلة 1 ، 3 ، 5 ، 7 ، 9؟', '5', '3', '7'),
      LibQuestion('نرمي قطعة نقدية مرة واحدة. ما احتمال الحصول على الوجه؟', '1/2', '1/3', '1'),
      LibQuestion('نرمي نردا مكعبا مرقما من 1 إلى 6. ما احتمال الحصول على العدد 6؟', '1/6', '1/2', '1/3'),
      LibQuestion('في كيس 3 كرات حمراء و 2 زرقاء. ما احتمال سحب كرة حمراء؟', '3/5', '2/5', '1/2'),
      LibQuestion('ما هو مدى السلسلة 3 ، 9 ، 12 ، 20؟', '17', '20', '12'),
      LibQuestion('التكرار النسبي لقيمة تكرارها 5 من أصل 20 هو:', '1/4', '1/5', '1/20'),
    ],
  ),
];
