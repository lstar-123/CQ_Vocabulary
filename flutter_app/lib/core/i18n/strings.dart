/// Centralized UI strings for i18n.
///
/// Every user-visible text MUST reference a key from this class.
/// The factory constructor selects the language based on [AppStrings.current].
abstract class AppStrings {
  AppStrings._();

  static AppStrings of() => _english; // default

  static final AppStrings _english = _EnglishStrings();
  static final AppStrings _chinese = _ChineseStrings();

  static void setEnglish() { /* future: use provider or locale */ }
  static void setChinese() { /* future: use provider or locale */ }

  // ── General ────────────────────────────────────────────────
  String get retry;
  String get loading;
  String get noData;
  String get errorGeneric;
  String get errorNetwork;
  String get errorServer;
  String get errorSession;
  String get close;
  String get done;
  String get next;
  String get previous;
  String get submit;
  String get skip;
  String get restart;
  String get backHome;
  String get save;
  String get cancel;

  // ── Auth ───────────────────────────────────────────────────
  String get login;
  String get logout;
  String get student;
  String get teacher;
  String get username;
  String get password;
  String get loginStudent;
  String get loginTeacher;
  String get registerPrompt;
  String get enterUsername;
  String get enterPassword;
  String get errorCredentials;

  // ── Home ───────────────────────────────────────────────────
  String hello(String name);
  String get studyModes;
  String get units;
  String get statistics;
  String get quizHistory;
  String get book;

  // ── Study Modes ────────────────────────────────────────────
  String get flashcard;
  String get flashcardDesc;
  String get spelling;
  String get spellingDesc;
  String get quiz;
  String get quizDesc;
  String get groupStudy;
  String get groupStudyDesc;

  // ── Flashcard ──────────────────────────────────────────────
  String get tapToReveal;
  String get tapToHide;
  String get pronounce;

  // ── Spelling ───────────────────────────────────────────────
  String get typeEnglish;
  String get tapToListen;
  String get correct;
  String get wrong;
  String answerIs(String answer);

  // ── Quiz ───────────────────────────────────────────────────
  String get chooseTranslation;
  String get quizResults;
  String excellent(int pct);
  String greatJob(int pct);
  String keepGoing(int pct);
  String keepPracticing(int pct);

  // ── Group Learning ─────────────────────────────────────────
  String groupProgress(int current, int total);
  String rememberedCount(int n, int total);
  String get remembered;
  String get forgot;
  String get stillWrong;
  String get gotIt;
  String get wrongReview;
  String get greatWork;

  // ── History ────────────────────────────────────────────────
  String get noHistoryYet;
  String get failedToLoadHistory;

  // ── Statistics ─────────────────────────────────────────────
  String get studySummary;
  String get accuracyTrend;
  String get weeklyActivity;
  String get learningDistribution;
  String get recentQuizzes;
  String get seeAll;
  String get noStudyRecords;
  String get startLearning;
  String get failedToLoadStats;
  String get wordsLabel;
  String get quizzesLabel;
  String get avgScoreLabel;
}

// ──────────────────────────────────────────────────────────────
// English
// ──────────────────────────────────────────────────────────────

class _EnglishStrings extends AppStrings {
  @override String get retry => 'Retry';
  @override String get loading => 'Loading…';
  @override String get noData => 'Nothing here yet';
  @override String get errorGeneric => 'Something went wrong';
  @override String get errorNetwork => 'No internet connection';
  @override String get errorServer => 'Server error, try later';
  @override String get errorSession => 'Session expired, please log in';
  @override String get close => 'Close';
  @override String get done => 'Done';
  @override String get next => 'Next';
  @override String get previous => 'Previous';
  @override String get submit => 'Submit';
  @override String get skip => 'Skip';
  @override String get restart => 'Restart';
  @override String get backHome => 'Back Home';
  @override String get save => 'Save';
  @override String get cancel => 'Cancel';

  @override String get login => 'Log in';
  @override String get logout => 'Log out';
  @override String get student => 'Student';
  @override String get teacher => 'Teacher';
  @override String get username => 'Username';
  @override String get password => 'Password';
  @override String get loginStudent => 'Log in';
  @override String get loginTeacher => 'Teacher Log in';
  @override String get registerPrompt => 'Create an account';
  @override String get enterUsername => 'Enter your username';
  @override String get enterPassword => 'Enter your password';
  @override String get errorCredentials => 'Wrong username or password';

  @override String hello(String name) => 'Hello, $name';
  @override String get studyModes => 'Study Modes';
  @override String get units => 'Units';
  @override String get statistics => 'Statistics';
  @override String get quizHistory => 'History';
  @override String get book => 'Book';

  @override String get flashcard => 'Flashcard';
  @override String get flashcardDesc => 'Flip & Learn';
  @override String get spelling => 'Spelling';
  @override String get spellingDesc => 'Write & Check';
  @override String get quiz => 'Quiz';
  @override String get quizDesc => 'Multiple Choice';
  @override String get groupStudy => 'Group';
  @override String get groupStudyDesc => 'Deep Memorize';

  @override String get tapToReveal => 'Tap to reveal';
  @override String get tapToHide => 'Tap to hide';
  @override String get pronounce => 'Pronounce';

  @override String get typeEnglish => 'Type the English word…';
  @override String get tapToListen => 'Tap to listen';
  @override String get correct => 'Correct';
  @override String get wrong => 'Wrong';
  @override String answerIs(String answer) => 'Answer: $answer';

  @override String get chooseTranslation => 'Choose the correct translation';
  @override String get quizResults => 'Quiz Results';
  @override String excellent(int pct) => 'Excellent! 🌟';
  @override String greatJob(int pct) => 'Great job! 🎉';
  @override String keepGoing(int pct) => 'Keep going! 💪';
  @override String keepPracticing(int pct) => 'Practice makes perfect! 📚';

  @override String groupProgress(int c, int t) => 'Group $c / $t';
  @override String rememberedCount(int n, int t) => '✓ $n / $t';
  @override String get remembered => 'Remembered';
  @override String get forgot => 'Forgot';
  @override String get stillWrong => 'Still Wrong';
  @override String get gotIt => 'Got it!';
  @override String get wrongReview => 'Wrong Review';
  @override String get greatWork => 'Great work! 🎉';

  @override String get noHistoryYet => 'No quiz history yet';
  @override String get failedToLoadHistory => 'Failed to load history';

  @override String get studySummary => 'Study Summary';
  @override String get accuracyTrend => 'Accuracy Trend';
  @override String get weeklyActivity => 'Weekly Activity';
  @override String get learningDistribution => 'Learning Distribution';
  @override String get recentQuizzes => 'Recent Quizzes';
  @override String get seeAll => 'See All';
  @override String get noStudyRecords => 'No study records yet';
  @override String get startLearning => 'Start learning today!';
  @override String get failedToLoadStats => 'Failed to load statistics';
  @override String get wordsLabel => 'Words';
  @override String get quizzesLabel => 'Quizzes';
  @override String get avgScoreLabel => 'Avg Score';
}

// ──────────────────────────────────────────────────────────────
// Chinese (简体中文)
// ──────────────────────────────────────────────────────────────

class _ChineseStrings extends AppStrings {
  @override String get retry => '重试';
  @override String get loading => '加载中…';
  @override String get noData => '暂无内容';
  @override String get errorGeneric => '出了点问题';
  @override String get errorNetwork => '网络未连接';
  @override String get errorServer => '服务器错误，请稍后';
  @override String get errorSession => '登录已过期，请重新登录';
  @override String get close => '关闭';
  @override String get done => '完成';
  @override String get next => '下一个';
  @override String get previous => '上一个';
  @override String get submit => '提交';
  @override String get skip => '跳过';
  @override String get restart => '重新开始';
  @override String get backHome => '返回首页';
  @override String get save => '保存';
  @override String get cancel => '取消';

  @override String get login => '登录';
  @override String get logout => '退出登录';
  @override String get student => '学生';
  @override String get teacher => '教师';
  @override String get username => '用户名';
  @override String get password => '密码';
  @override String get loginStudent => '登录';
  @override String get loginTeacher => '教师登录';
  @override String get registerPrompt => '创建账号';
  @override String get enterUsername => '请输入用户名';
  @override String get enterPassword => '请输入密码';
  @override String get errorCredentials => '用户名或密码错误';

  @override String hello(String name) => '你好，$name';
  @override String get studyModes => '学习模式';
  @override String get units => '单元';
  @override String get statistics => '统计';
  @override String get quizHistory => '历史';
  @override String get book => '词书';

  @override String get flashcard => '闪卡';
  @override String get flashcardDesc => '翻转学习';
  @override String get spelling => '拼写';
  @override String get spellingDesc => '听写练习';
  @override String get quiz => '测验';
  @override String get quizDesc => '选择题';
  @override String get groupStudy => '分组';
  @override String get groupStudyDesc => '深度记忆';

  @override String get tapToReveal => '点击显示';
  @override String get tapToHide => '点击隐藏';
  @override String get pronounce => '发音';

  @override String get typeEnglish => '输入英文单词…';
  @override String get tapToListen => '点击发音';
  @override String get correct => '正确';
  @override String get wrong => '错误';
  @override String answerIs(String answer) => '正确答案：$answer';

  @override String get chooseTranslation => '选择正确的中文翻译';
  @override String get quizResults => '测验结果';
  @override String excellent(int pct) => '太棒了！🌟';
  @override String greatJob(int pct) => '做得好！🎉';
  @override String keepGoing(int pct) => '继续加油！💪';
  @override String keepPracticing(int pct) => '多加练习！📚';

  @override String groupProgress(int c, int t) => '第 $c 组 / 共 $t 组';
  @override String rememberedCount(int n, int t) => '✓ $n / $t';
  @override String get remembered => '记住了';
  @override String get forgot => '忘记了';
  @override String get stillWrong => '还是错了';
  @override String get gotIt => '记住了！';
  @override String get wrongReview => '错词复习';
  @override String get greatWork => '太棒了！🎉';

  @override String get noHistoryYet => '还没有测验记录';
  @override String get failedToLoadHistory => '加载历史失败';

  @override String get studySummary => '学习摘要';
  @override String get accuracyTrend => '正确率趋势';
  @override String get weeklyActivity => '每周活动';
  @override String get learningDistribution => '学习分布';
  @override String get recentQuizzes => '最近测验';
  @override String get seeAll => '查看全部';
  @override String get noStudyRecords => '还没有学习记录';
  @override String get startLearning => '今天就开始学习吧！';
  @override String get failedToLoadStats => '加载统计失败';
  @override String get wordsLabel => '单词';
  @override String get quizzesLabel => '测验';
  @override String get avgScoreLabel => '平均分';
}
