use Amnesia

defdatabase WordDB do
  # word is the index of this table
  deftable WordInfo, [:word, :syllables, :pronounciation], type: :set do
    @type t :: %WordInfo{word: String.t, syllables: String.t, pronounciation: String.t}

    def word_info(self) do
      WordInfo.read(self.word)
    end
  end
end