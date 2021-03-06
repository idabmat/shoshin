class Lesson < ApplicationRecord
  include Editable

  belongs_to :teaching, inverse_of: :lessons
  has_many :copies, class_name: 'Lesson', inverse_of: :original, foreign_key: :original_id, dependent: :nullify
  belongs_to :original, class_name: 'Lesson', foreign_key: :original_id, inverse_of: :copies, required: false
  has_many :authors, through: :authorships, source: :author, inverse_of: :lessons
  has_many :steps, -> { order(position: :asc) }, inverse_of: :lesson, dependent: :destroy
  has_many :chapter_lessons, inverse_of: :lesson, dependent: :destroy
  has_many :chapters, through: :chapter_lessons
  has_many :levels, through: :editable_levels, source: :level, inverse_of: :lessons

  validates :name, :popularity, :teaching, presence: true
  validates :shared, exclusion: { in: [nil] }

  delegate :name, to: :teaching, prefix: true
  delegate :short_name, to: :teaching, prefix: true

  ransacker :is_used do
    Arel.sql('(SELECT EXISTS (SELECT 1 FROM chapter_lessons WHERE chapter_lessons.lesson_id = lessons.id))')
  end

  def create_copy(teacher)
    copy = Lesson.new(name: name, teaching: teaching, level_ids: level_ids, original_id: id)
    steps.map { |step| step.build_copy(copy) }
    copy.save!
    copy.update(authors: [teacher])
    increment!(:popularity)
    copy
  end
end
