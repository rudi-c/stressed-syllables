import en_core_web_sm # spacy

nlp = None

def load_model():
    global nlp
    nlp = en_core_web_sm.load()

def analyze_text(text):
    analyzed = nlp(unicode(text))
    tokens = [(word.text, word.idx, word.pos_) for word in analyzed]
    lines = break_into_lines(tokens)
    return lines

def break_into_lines(tokens):
    lines = []
    current_line = []
    current_line_idx = 0
    for token in tokens:
        (text, index, pofspeech) = token
        newline_count = text.count("\n")
        if pofspeech == "SPACE" and newline_count > 0:
            current_line_idx = index + len(text)
            for _ in range(newline_count):
                lines.append(current_line)
                current_line = []
        else:
            assert newline_count == 0
            if not pofspeech in ["PUNCT", "NUM", "SYM"]:
                current_line.append((text, index - current_line_idx, pofspeech))
    lines.append(current_line)
    return lines
