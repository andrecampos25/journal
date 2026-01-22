

class QuotesLogic {
  static final List<Map<String, String>> _quotes = [
    {'text': 'The only way to deal with an unfree world is to become so absolutely free that your very existence is an act of rebellion.', 'author': 'Albert Camus'},
    {'text': 'He who has a why to live can bear almost any how.', 'author': 'Friedrich Nietzsche'},
    {'text': 'Happiness depends upon ourselves.', 'author': 'Aristotle'},
    {'text': 'Waste no more time arguing about what a good man should be. Be one.', 'author': 'Marcus Aurelius'},
    {'text': 'It is not death that a man should fear, but he should fear never beginning to live.', 'author': 'Marcus Aurelius'},
    {'text': 'Man conquers the world by conquering himself.', 'author': 'Zeno of Citium'},
    {'text': 'No man is free who is not master of himself.', 'author': 'Epictetus'},
    {'text': 'The best revenge is not to be like your enemy.', 'author': 'Marcus Aurelius'},
    {'text': 'You have power over your mind - not outside events. Realize this, and you will find strength.', 'author': 'Marcus Aurelius'},
    {'text': 'We suffer more often in imagination than in reality.', 'author': 'Seneca'},
    {'text': 'If you want to improve, be content to be thought foolish and stupid.', 'author': 'Epictetus'},
    {'text': 'Difficulty shows what men are.', 'author': 'Epictetus'},
    {'text': 'Luck is what happens when preparation meets opportunity.', 'author': 'Seneca'},
    {'text': 'To be calm is the highest achievement of the self.', 'author': 'Zen Proverb'},
    {'text': 'Act as if what you do makes a difference. It does.', 'author': 'William James'},
    {'text': 'Do what you can, with what you have, where you are.', 'author': 'Theodore Roosevelt'},
    {'text': 'Believe you can and you\'re halfway there.', 'author': 'Theodore Roosevelt'},
    {'text': 'It does not matter how slowly you go as long as you do not stop.', 'author': 'Confucius'},
    {'text': 'Our life is what our thoughts make it.', 'author': 'Marcus Aurelius'},
    {'text': 'The privilege of a lifetime is to become who you truly are.', 'author': 'Carl Jung'},
    {'text': 'Your visions will become clear only when you can look into your own heart. Who looks outside, dreams; who looks inside, awakes.', 'author': 'Carl Jung'},
    {'text': 'I am not what happened to me, I am what I choose to become.', 'author': 'Carl Jung'},
    {'text': 'Knowing your own darkness is the best method for dealing with the darknesses of other people.', 'author': 'Carl Jung'},
    {'text': 'In the midst of winter, I found there was, within me, an invincible summer.', 'author': 'Albert Camus'},
    {'text': 'Man is condemned to be free; because once thrown into the world, he is responsible for everything he does.', 'author': 'Jean-Paul Sartre'},
    {'text': 'Life is not a problem to be solved, but a reality to be experienced.', 'author': 'Søren Kierkegaard'},
    {'text': 'Life can only be understood backwards; but it must be lived forwards.', 'author': 'Søren Kierkegaard'},
    {'text': 'An unexamined life is not worth living.', 'author': 'Socrates'},
    {'text': 'To find yourself, think for yourself.', 'author': 'Socrates'},
    {'text': 'I know that I know nothing.', 'author': 'Socrates'},
    {'text': 'Beware the barrenness of a busy life.', 'author': 'Socrates'},
    {'text': 'There is only one good, knowledge, and one evil, ignorance.', 'author': 'Socrates'},
    {'text': 'Wonder is the beginning of wisdom.', 'author': 'Socrates'},
  ];

  static Map<String, String> getDailyQuote() {
    final now = DateTime.now();
    // Use day of year as seed to ensure same quote for the whole day
    final dayOfYear = int.parse('${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
    final index = dayOfYear % _quotes.length;
    return _quotes[index];
  }
}
