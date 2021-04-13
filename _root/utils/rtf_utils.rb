module RTFUtils
  extend self

  def newline
    '\line '
  end

  def tab
    '    '
  end

  def bold(text)
    '}{\rtlch\fcs1 \ab\af1\afs22 \ltrch\fcs0 \b\fs22\lang1033\langfe4096\langnp1033\insrsid4484739\charrsid4653131 \hich\af1\dbch\af31505\loch\f1 ' +
        text + 
        '}{\rtlch\fcs1 \af1\afs22 \ltrch\fcs0 \fs22\lang1033\langfe4096\langnp1033\insrsid4484739 \hich\af1\dbch\af31505\loch\f1'
  end

  def italics(text)
    '}{\rtlch\fcs1 \ai\af1\afs22 \ltrch\fcs0 \i\fs22\lang1033\langfe4096\langnp1033\insrsid4484739\charrsid14746555 \hich\af1\dbch\af31505\loch\f1 ' +
        text +
        '}{\rtlch\fcs1 \af1\afs22 \ltrch\fcs0 \fs22\lang1033\langfe4096\langnp1033\insrsid4484739 \hich\af1\dbch\af31505\loch\f1 '
  end
end
