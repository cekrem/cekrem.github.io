(function () {
  const quotes = [
    "I am the way, the truth, and the life. — John 14:6",
    "I am the resurrection and the life. — John 11:25",
    "I am the light of the world. — John 8:12",
    "I am the bread of life. — John 6:35",
    "I am the good shepherd. — John 10:11",
    "I am the true vine. — John 15:1",
    "I have come that they may have life, and have it to the full. — John 10:10",
    "For God so loved the world that he gave his one and only Son. — John 3:16",
    "You will know the truth, and the truth will set you free. — John 8:32",
    "Peace I leave with you; my peace I give you. — John 14:27",
    "Greater love has no one than this: to lay down one's life for one's friends. — John 15:13",
    "Let anyone who is thirsty come to me and drink. — John 7:37",
    "Do not let your hearts be troubled. — John 14:1",
    "I am the vine; you are the branches. — John 15:5",
    "Before Abraham was born, I am! — John 8:58",
    "My sheep listen to my voice; I know them, and they follow me. — John 10:27",
    "Ask and you will receive, and your joy will be complete. — John 16:24",
    "Whoever believes in me will never be thirsty. — John 6:35",
    "Very truly I tell you, whoever hears my word has eternal life. — John 5:24",
    "I give them eternal life, and they shall never perish. — John 10:28",
  ]
    .sort(() => Math.random() > 0.5)
    .map((quote) => document.createComment(quote));

  const targets = Array.from(
    document.body.querySelectorAll(
      "p, a, h1, h2, h3, li, section, article, footer, header",
    ),
  )
    .sort(() => Math.random() > 0.5)
    .slice(0, quotes.length);

  targets.forEach((target, i) => target.before(quotes[i]));
})();
