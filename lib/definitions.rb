module Definitions

  PROFILE_FIELDS = {
      "Enrollment" => {
           "application_process" => "Application Process",
                "admissions_url" => "Admissions URL",
               "application_fee" => "Application Fee",
        "application_fee_amount" => "Application Fee Amount",
         "applications_received" => "Applications Received",
             "students_accepted" => "Students Accepted",
                 "feeder_school" => "Feeder School",
            "destination_school" => "Destination School",
      },
      'Classes' => {
                "academic_focus" => "Academic Focus",
           "instructional_model" => "Instructional Model",
                   "arts_visual" => "Arts - Visual",
                    "arts_media" => "Arts - Media",
                    "arts_music" => "Arts - Music",
       "arts_performing_written" => "Arts - Performing & Written",
                     "immersion" => "Immersion",
              "foreign_language" => "Foreign Language",
                    "ap_classes" => 'AP Classes',
               "dual_enrollment" => 'Dual Enrollment',
    "dual_enrollment_institutio" => 'Dual Enrollment Institution',
      },
      'Culture' => {
                    "dress_code" => "Dress Code",
               "bullying_policy" => "Bullying Policy",
            "parent_involvement" => "Parent Involvement",
      },
      'Support' => {
              "special_ed_level" => "Special Education Level",
           "special_ed_programs" => "Special Education Programs",
                     "ell_level" => "ELL Level",
                 "ell_languages" => "ELL Languages",
                  "college_prep" => "College Prep",
      "extra_learning_resources" => "Extra Learning Resources",
                    "facilities" => "Facilities",
               "skills_training" => "Skills Training",
             "before_after_care" => "Before/After Care",
               "staff_resources" => "Staff Resources",
      },
      'Extracurricular' => {
                   "boys_sports" => "Boys Sports",
                  "girls_sports" => "Girls Sports",
                 "student_clubs" => "Student Clubs",
           "student_clubs_dance" => "Student Clubs Dance",
        "student_clubs_language" => "Student Clubs Language",
           "student_clubs_other" => "Student Clubs Other"
      },
=begin
      'Other' => {
        "after_school_transportatio" => 'After School Transportation',
        "character_development" => 'Character Development',
        "college_counseling" => 'College Counseling',
        "counselor_student_ratio" => 'Counselor-to-Student Ratio',
        "discipline_programs" => 'Discipline Programs',
        "early_child_center_relatio" => 'Early Childhood Center Relations',
        "early_childhood_programs" => 'Early Childhood Programs',
        "early_childhood_transition" => 'Early Childhood Transition',
        "email" => 'Email',
        "english_language_learners" => 'English Language Learners',
        "family_supports" => 'Family Support',
        "in_school_programs" => 'In-School Programs',
        "organized_sports" => 'Sports',
        "parent_supports" => 'Parent Support',
        "special_needs" => "Special Needs Students",
        "special_tracks" => "Special Tracks",
        "student_development_progra" => "Student Development Programs",
        "student_leadership_opportu" => "Student Leadership Opportunities",
        "transportation" => "Transportation",
          "transportation_options" => "Transportation",
                 "dual_enrollment" => "Dual Enrollment",
      "dual_enrollment_institutio" => "Dual Enrollment Institutions",
                 "family_supports" => "Family Supports",
                 "parent_supports" => "Parent Supports",
                        "schedule" => "Schedule",
      "student_leadership_opportu" => "Student Leadership Opportunities",
      "student_development_progra" => "Student Development Programs",
                  "special_tracks" => "Special Tracks",
        "early_childhood_programs" => "Early Childhood Programs",
                    "facebook_url" => "Facebook URL",
                      "school_url" => "School URL",
      }
=end
    }
    
    
    VALUE_LABELS = {
      '0' => 'No',
      '1' => 'Yes',
                    "academic_focus" => "Please indicate if your school has a special academic theme or area of focus",
                 "special_education" => "Special Education",
                        "vocational" => "Vocational education",
                        "technology" => "Technology",
                          "all_arts" => "Arts (all)",
                      "foreign_lang" => "Foreign languages",
                         "religious" => "Religious",
                          "business" => "Business",
                       "visual_arts" => "Visual arts",
                   "performing_arts" => "Performing arts",
                           "medical" => "Medical",
                             "music" => "Music room",
                       "engineering" => "Engineering",
                  "service_learning" => "Service learning",
                       "mathematics" => "Mathematics",
                           "science" => "Science lab",
                              "none" => "None",
               "instructional_model" => "What instructional and/or curriculum modes does your school use, if any?",
                        "montessori" => "Montessori",
                        "AP_courses" => "Advanced placement courses",
                                "ib" => "International Baccalaureate (IB)",
                            "honors" => "Honors track",
                            "gifted" => "Gifted/High performing",
                      "continuation" => "Continuation",
                    "core_knowledge" => "Core knowledge",
                           "waldorf" => "Waldorf",
                "accelerated_credit" => "Accelerated credit earning",
                 "independent_study" => "Independent study",
                           "virtual" => "Virtual school",
                          "adult_ed" => "Adult education",
                         "classical" => "Classical",
                "direct_instruction" => "Direct instruction",
                               "ged" => "GED",
            "individual_instruction" => "Individually guided instruction",
                       "internships" => "Internships",
                           "outdoor" => "Outdoor learning lab",
                            "reggio" => "Reggio Emilia",
                       "therapeutic" => "Therapeutic",
                   "standards-based" => "Standards-based",
                             "other" => "Other",
                     "project_based" => "Project-based",
         "instructional_model_other" => "Open text",
                        "arts_media" => "Arts - Media",
                         "animation" => "Computer animation",
                          "graphics" => "Graphics",
                       "tech_design" => "Technical design and production",
                             "video" => "Video / Film production",
                        "arts_music" => "Arts - Music",
                              "band" => "Band",
                     "chamber music" => "Chamber music",
                             "bells" => "Bell / Handbell choir",
                             "opera" => "Opera",
                         "rock_band" => "Rock band",
                      "music_theory" => "Theory",
                         "jazz_band" => "Jazz Band",
                            "chorus" => "Choir / Chorus",
                         "orchestra" => "Orchestra",
                     "music_lessons" => "Instrumental music lessons",
                             "voice" => "Vocal lessons / coaching",
           "arts_performing_written" => "Arts - Performing and Written",
                            "improv" => "Improv",
                            "poetry" => "Poetry",
                             "dance" => "Dance club",
                             "drama" => "Drama",
                  "creative_writing" => "Creative Writing",
                       "arts_visual" => "Arts - Visual",
                          "ceramics" => "Ceramics",
                       "printmaking" => "Printmaking",
                         "sculpture" => "Sculpture",
                          "textiles" => "Textile design",
                            "design" => "Industrial / graphic design",
                           "drawing" => "Drawing / Sketching",
                          "painting" => "Painting",
                       "photography" => "Photography",
                      "architecture" => "Architecture",
                    "transportation" => "What kind of transportation is provided for students by the school/district?",
                            "passes" => "Passes/tokens for public transportation",
                            "busses" => "Busses/vans for our students only",
                        "shared_bus" => "School shares bus/van with other schools",
                   "special_ed_only" => "Transportation provided for special education students only",
              "transportation_other" => "Open text",
                   "staff_resources" => "What staff resources are available to students?",
               "assistant_principal" => "Assistant principal",
                       "art_teacher" => "Art teacher",
                             "nurse" => "Nurse",
                "reading_specialist" => "Reading specialist",
                             "tutor" => "Tutor",
                         "librarian" => "Librarian/media specialist",
               "computer_specialist" => "Computer specialist",
                     "music_teacher" => "Music teacher",
                    "poetry_teacher" => "Poetry/Creative writing teacher",
                  "robotics_teacher" => "Robotics/Technology specialist",
                     "ell_esl_coord" => "ELL/ESL Coordinator",
                     "dance_teacher" => "Dance teacher",
                 "college_counselor" => "College counselor",
                          "security" => "Security personnel",
                     "pe_instructor" => "PE instructor",
                       "teacher_aid" => "Teacher aid/assistant teacher",
                            "priest" => "Priest, pastor, or other religious personnel",
                 "instructional_aid" => "Instructional aide/coach",
                   "math_specialist" => "Math specialist",
               "school_psychologist" => "School psychologist",
                   "school_counslor" => "School social worker/counselor",
            "special_ed_coordinator" => "Special education coordinator",
                 "gifted_specialist" => "Gifted specialist",
                  "speech_therapist" => "Speech and language therapist",
                    "garden_teacher" => "Gardening teacher",
                   "cooking_teacher" => "Cooking/Nutrition teacher",
                     "spec_ed_level" => "Select one of these options to describe the special education programming at your school",
                             "basic" => "Basic - we offer or partner to provide services based on the needs of individual students",
                          "moderate" => "Moderate - we consistently offer a full program for particular ESL/ELL needs",
                         "intensive" => "Intensive - we offer a full program for many languages and/or we offer at least one very comprehensive program school-wide for at least 25% of our population",
               "special_ed_programs" => "Does your school have a specialized program for specific types of special education students? If so, please indicate below.",
                            "autism" => "Autism",
                         "blindness" => "Visual impairments",
                          "deafness" => "Hearing impairments",
                         "emotional" => "Emotional behavioral disabilities",
                            "speech" => "Speech and language impairments",
                                "ld" => "Specific learning disabilities",
               "developmental_delay" => "Significant developmental delay",
                        "orthopedic" => "Orthopedic impairments",
                          "multiple" => "Multiple disabilities",
                         "cognitive" => "Cognitive disability",
                       "boys_sports" => "Boys sports",
                        "basketball" => "Basketball",
                            "soccer" => "Soccer",
                      "cheerleading" => "Cheerleading",
                        "gymnastics" => "Gymnastics",
                        "ice_hockey" => "Ice Hockey",
                          "lacrosse" => "Lacrosse",
                        "water_polo" => "Water Polo",
                         "badminton" => "Badminton",
                              "crew" => "Crew / Rowing",
                           "cycling" => "Cycling",
                            "diving" => "Diving",
                        "equestrian" => "Equestrian",
                      "martial_arts" => "Martial arts (judo, tae kwon do, karate, etc.)",
                          "kayaking" => "Kayaking",
                          "kickball" => "Kickball",
                    "weight_lifting" => "Power lifting / Weight lifting",
                             "rugby" => "Rugby",
                           "sailing" => "Sailing",
                               "ski" => "Skiing",
                            "squash" => "Squash",
                           "surfing" => "Surfing",
                          "ultimate" => "Ultimate Frisbee",
                     "cross_country" => "Cross Country",
                          "football" => "Football",
                            "tennis" => "Tennis",
                          "swimming" => "Swimming pool",
                         "wrestling" => "Wrestling",
                             "track" => "Track",
                          "baseball" => "Baseball",
                              "golf" => "Golf",
                           "fencing" => "Fencing",
                     "flag_football" => "Flag Football",
                        "volleyball" => "Volleyball",
                 "boys_sports_other" => "Open text",
                      "girls_sports" => "Girls sports",
                          "softball" => "Softball",
                      "field_hockey" => "Field Hockey",
                "girls_sports_other" => "Open text",
                         "ell_level" => "Please select one of these options to describe the ESL/ELL programming at your school",
                     "ell_languages" => "Select languages",
                            "arabic" => "Arabic languages",
                           "amharic" => "Amharic",
                         "cantonese" => "Chinese (Cantonese)",
                          "mandarin" => "Chinese (Mandarin)",
                             "dutch" => "Dutch",
                            "french" => "French",
                            "german" => "German",
                             "hmong" => "Hmong",
                           "italian" => "Italian",
                          "japanese" => "Japanese",
                            "korean" => "Korean",
                           "russian" => "Russian",
                           "spanish" => "Spanish",
                           "tagalog" => "Tagalog",
                              "urdu" => "Urdu",
                        "vietnamese" => "Vietnamese",
                        "facilities" => "What facilities and resources does your school have?",
                        "auditorium" => "Auditorium",
                         "cafeteria" => "Cafeteria",
                               "gym" => "Gym",
                           "library" => "Library",
                          "computer" => "Computer lab",
                    "college_center" => "College/career center",
                            "chapel" => "Chapel/spiritual reflection center",
                            "garden" => "Garden/Greenhouse",
                        "playground" => "Playground",
                     "sports_fields" => "Access to sports fields",
                       "audiovisual" => "Audiovisual aids",
                          "internet" => "Internet access",
                               "art" => "Art room",
                      "learning_lab" => "Learning lab",
                     "multi_purpose" => "Multi-purpose room (\"cafegymatorium\")",
                       "performance" => "Performance stage",
                              "farm" => "Access to farm or natural area",
                        "industrial" => "Industrial shop",
                           "kitchen" => "Kitchen",
                            "parent" => "Parent center",
                        "dress_code" => "Dress code",
                           "uniform" => "Uniforms",
                     "no_dress_code" => "Neither",
                          "schedule" => "Is there anything special about your school's schedule?",
                         "yearround" => "Year-round / Rolling admissions, if space is available.",
                          "parttime" => "Part-time study",
                          "extended" => "Extended/longer school day",
                             "block" => "Block scheduling",
                      "college_prep" => "What college preparation/awareness resources does your school provide to students?",
                      "prep_classes" => "College prep programs/courses during the year",
                     "info_sessions" => "College presentations or information sessions",
                 "community_college" => "Community college courses",
                      "sat_act_prep" => "SAT/ACT prep classes",
                       "summer_prep" => "Summer college prep programs",
                     "college_trips" => "School-sponsored trips to college campuses",
                "visiting_lecturers" => "Visiting teachers or lecturers from colleges",
                   "skills_training" => "What vocational or skills-based training programs does your school offer students, if any?",
                         "mechanics" => "Auto mechanics",
                        "management" => "Business management",
                       "programming" => "Computer programming",
                      "construction" => "Construction / building",
                          "culinary" => "Culinary",
                        "electrical" => "Electrical",
                              "hvac" => "HVAC certification",
                        "it_support" => "IT support",
                          "plumbing" => "Plumbing",
                            "prelaw" => "Pre-law",
                           "welding" => "Welding certification",
                 "before_after_care" => "Does your school have before or after care on site?",
                             "after" => "After school care",
                            "before" => "Before school care",
                   "bullying_policy" => "Does your school have a bullying and/or cyber bulling policy in place?",
                                 "y" => "Yes",
                                 "n" => "No",
                         "immersion" => "Does your school offer any bilingual/language immersion programs?",
                               "yes" => "Yes",
                                "no" => "No",
                "student_enrollment" => "School size",
                            "Number" => "n/a",
          "extra_learning_resources" => "What extra learning resources are offered for students?",
                       "remediation" => "Remediation",
                 "career_counseling" => "Career/college counseling",
                         "mentoring" => "Mentoring",
                        "counseling" => "Counseling",
                      "acceleration" => "Acceleration",
                    "differentiated" => "Differentiated learning programs",
    "extra_learning_resources_other" => "Other",
                         "Open text" => "n/a",
                  "foreign_language" => "What foreign languages are taught at your school?",
                             "latin" => "Latin",
            "foreign_language_other" => "Other",
                      "grade_levels" => "Grade levels offered (We do check boxes for this, but comma separated is fine too)",
                                "pk" => "PK",
                                 "k" => "K",
                                 "1" => "First Grade",
                                 "2" => "Second Grade",
                                 "3" => "Third Grade",
                                 "4" => "Fourth Grade",
                                 "5" => "Fifth Grade",
                                 "6" => "Sixth Grade",
                                 "7" => "Seventh Grade",
                                 "8" => "Eighth Grade",
                                 "9" => "Ninth Grade",
                                "10" => "Tenth Grade",
                                "11" => "Eleventh Grade",
                                "12" => "Twelfth Grade",
                      "facebook_url" => "School Facebook page",
                        "school_url" => "School web site",
                "parent_involvement" => "How do parents get involved at your school?",
                 "parent_nights_req" => "Attend parent nights",
                     "chaperone_req" => "Chaperone school trips",
                         "coach_req" => "Coach sports teams or extracurricular activities",
                       "pto_pta_req" => "Join PTO/PTA",
                    "playground_req" => "Monitor the playground",
                      "cultural_req" => "Organize cultural events",
                   "fundraising_req" => "Organize fundraising events (school auction, bake sales, etc.)",
                  "presentation_req" => "Present special topics during curricular units",
                    "governance_req" => "Serve on school improvement team or governance council",
                         "tutor_req" => "Tutor",
                     "classroom_req" => "Volunteer in the classroom",
                  "after_school_req" => "Volunteer time after school",
           "school_type_affiliation" => "School type (Private schools only)",
                  "religious_paroch" => "Religious / Parochial",
                       "independent" => "Independent",
     "school_type_affiliation_other" => "Affiliation:",
               "application_process" => "Is there an application process for your school?",
                    "admissions_url" => "Send parents to your admissions page",
              "application_deadline" => "When is the application deadline?",
                   "parents_contact" => "Parents should contact the school for more information on deadlines",
      "Calendar select (MM/DD/YYYY)" => "Date: [application_deadline_date]",
                   "application_fee" => "Is there an application fee?",
             "applications_received" => "How many applications did you receive this year?",
                 "students_accepted" => "How many students did you accept this year?",
             "feeder_school_[1,2,3]" => "What school(s) do students typically attend before yours? (We allow three)",
        "destination_school_[1,2,3]" => "What school(s) do students typically attend after they graduate your school? (We allow three)",
            "academic_award_[1,2,3]" => "Has your school received any awards in the past 3 years? (We allow three)",
       "academic_award_[1,2,3]_year" => "Year:",
    "dropdown (2010,2011,2012,2013)" => "n/a",
                     "school_colors" => "What are your school colors?",
                    "best_known_for" => "What is your school best known for?",
               "administrator_email" => "School leader's email",
                "administrator_name" => "School leader's name",
                        "start_time" => "What time does school start each day? Indicate classroom start time only, not before-school programming.",
                   "time (12:00 AM)" => "n/a",
                          "end_time" => "What time does school end each day? Indicate classroom end time only, not after-school programming.",
                     "student_clubs" => "Student clubs (Note that clubs are distinct from courses)",
                         "drum_line" => "Drum line",
                          "art_club" => "Art club",
                         "book_club" => "Book/reading club",
                             "chess" => "Chess club",
                            "debate" => "Debate",
                         "game_club" => "Game club",
                         "gardening" => "Gardening",
                       "girl_scouts" => "Girl Scouts",
                         "math_club" => "Math club",
                        "mock_trial" => "Mock trial competition club",
                 "student_newspaper" => "Student newspaper",
                          "robotics" => "Robotics club",
                      "science_club" => "Science club",
                          "yearbook" => "Yearbook",
                        "drill_team" => "Drill team",
             "amnesty_international" => "Amnesty International",
                             "anime" => "Anime club",
                       "arts_crafts" => "Arts and crafts",
                     "homework_help" => "Homework help/study buddy club",
                 "community_service" => "Community service",
                           "cooking" => "Cooking club",
                              "deca" => "DECA",
                        "boy_scouts" => "Boy Scouts",
                        "cub_scouts" => "Cub Scouts",
                               "fca" => "Fellowship of Christian Athletes (FCA)",
                        "flag_girls" => "Flag girls",
                     "language_club" => "Foreign language and culture club",
                              "fbla" => "Future Business Leaders of America (FBLA)",
                  "girls_on_the_run" => "Girls on the Run",
                   "sewing_knitting" => "Sewing/knitting club",
                           "habitat" => "Habitat for Humanity",
                               "nhs" => "National Honor Society",
                      "its_academic" => "It's Academic",
                             "jrotc" => "JROTC",
           "lesbian_gay_transgender" => "Lesbian, gay, transgender club",
                      "literary_mag" => "Literary magazine",
                  "special_olympics" => "Special Olympics",
                              "mime" => "Mime club",
                         "step_team" => "Step team",
                    "model_congress" => "Model Congress",
                         "model_oas" => "Model OAS",
                          "model_un" => "Model UN",
                      "student_govt" => "Student council/government",
                           "origami" => "Origami club",
                         "recycling" => "Recycling club",
                              "sadd" => "SADD",
                        "drama_club" => "Drama club",
                              "yoga" => "Yoga club",
                         "tech_club" => "Technology club",
                     "tv_radio_news" => "Television/Radio News",
                          "woodshop" => "Woodshop",
               "student_clubs_dance" => "Type of dance club",
            "student_clubs_language" => "Type language club",
       "student_clubs_other_1"       => "Other",
       "student_clubs_other_2"       => "Other",
       "student_clubs_other_3"       => "Other",

      "arthistory" => "Art History",
         "biology" => "Biology",
          "calcab" => "Calculus AB",
          "calcbc" => "Calculus BC",
       "chemistry" => "Chemistry",
         "chinese" => "Chinese Language and Culture",
         "compsci" => "Computer Science A",
     "englangcomp" => "English Language and Composition",
      "englitcomp" => "English Literature and Composition",
      "envscience" => "Environmental Science",
     "eurohistory" => "European History",
          "french" => "French Language and Culture",
          "german" => "German Language and Culture",
     "govpolicomp" => "Government and Politics: Comparative",
       "govpolius" => "Government and Politics: United States",
        "humangeo" => "Human Geography",
         "italian" => "Italian Language and Culture",
        "japanese" => "Japanese Language and Culture",
           "latin" => "Latin",
           "macro" => "Macroeconomics",
           "micro" => "Microeconomics",
     "musictheory" => "Music Theory",
        "physicsb" => "Physics B",
      "physicscem" => "Physics C: Electricity and Magnetism",
    "physicscmech" => "Physics C: Mechanics",
           "psych" => "Psychology",
     "spanishlang" => "Spanish Language",
      "spanishlit" => "Spanish Literature and Culture",
           "stats" => "Statistics",
        "studio2d" => "Studio Art: 2-D Design",
        "studio3d" => "Studio Art: 3-D Design",
      "studiodraw" => "Studio Art: Drawing",
       "ushistory" => "United States History",
    "worldhistory" => "World History",

   }
     
     
    FILTERS = [
      {
        :key     => :grade,
        :title   => 'Grade Level',
        :options => [
          ['Pre-Schools', 'grades_served', 'ec'],
          ['Elementary Schools', 'grades_served', 'elementary'],
          ['Middle Schools', 'grades_served', 'middle'],
          ['High Schools', 'grades_served', 'high'],
        ],
      },
      {
        :key     => :arts,
        :title   => 'Arts and Music',
        :options => [
          ['Band', 'arts_music', 'band'],
          ['Ceramics', 'arts_visual', 'ceramics'],
          ['Choir / chorus', 'arts_music', 'chorus'],
          ['Computer graphics', 'arts_media', ['graphics', 'animation']],
          ['Creative writing',	'arts_performing_written',	'creative_writing'],
          ['Dance',	'arts_performing_written',	'dance'],
          ['Drama',	'arts_performing_written',	'drama'],
          ['Drawing',	'arts_visual',	'drawing'],
          ['Instrumental music lessons',	'arts_music',	'music_lessons'],
          ['Jazz band',	'arts_music',	'jazz_band'],
          ['Orchestra', 'arts_music',	'orchestra'],
          ['Painting',	'arts_visual',	'painting'],
          ['Photography',	'arts_visual',	'photography'],
          ['Video / Film production',	'arts_media',	'video'],
		    ],
      },
      {
        :key     => :support,
        :title   => 'Student Support',
        :options => [
          ['English Language Learners', 'ell_level', ['basic', 'moderate', 'intensive']],
          ['Autism', 'special_ed_programs', 'autism'],
          ['Visual impairments',	'special_ed_programs',	'blindness'],
          ['Hearing impairments',	'special_ed_programs',	'deafness'],
          ['Emotional behavioral disabilities',	'special_ed_programs',	'emotional'],
          ['Speech and language impairments',	'special_ed_programs',	'speech'],
          ['Specific learning disabilities',	'special_ed_programs',	'ld'],
          ['Significant developmental delay',	'special_ed_programs',	'developmental_delay'],
          ['Orthopedic impairments',	'special_ed_programs',	'orthopedic'],
          ['Multiple disabilities',	'special_ed_programs',	'multiple'],
          ['Other health impairments',	'special_ed_programs',	'other'],
          ['Cognitive disability',	'special_ed_programs',	'cognitive'],
        ],
      },
      {
        :key     => :sports,
        :title   => 'Sports',
        :options => [
          ['Baseball',	['boys_sports', 'girls_sports'],	'baseball'],
          ['Basketball',	['boys_sports', 'girls_sports'],	'basketball'],
          ['Cheerleading',	['boys_sports', 'girls_sports'],	'cheerleading'],
          ['Crew / Rowing',	['boys_sports', 'girls_sports'],	'crew'],
          ['Cross country',	['boys_sports', 'girls_sports'],	'cross_country'],
          ['Fencing',	['boys_sports', 'girls_sports'],	'fencing'],
          ['Football',	['boys_sports', 'girls_sports'],	'football'],
          ['Golf',	['boys_sports', 'girls_sports'], 'golf'],
          ['Ice hockey',	['boys_sports', 'girls_sports'],	'ice_hockey'],
          ['Judo / Other martial arts',	['boys_sports', 'girls_sports'],	'martial_arts'],
          ['Lacrosse',	['boys_sports', 'girls_sports'],	'lacrosse'],
          ['Rugby',	['boys_sports', 'girls_sports'],	'rugby'],
          ['Skiing',	['boys_sports', 'girls_sports'],	'skiing'],
          ['Soccer',	['boys_sports', 'girls_sports'],	'soccer'],
          ['Softball',	['boys_sports', 'girls_sports'],	'softball'],
          ['Swimming',	['boys_sports', 'girls_sports'],	'swimming'],
          ['Tennis',	['boys_sports', 'girls_sports'],	'tennis'],
          ['Track',	['boys_sports', 'girls_sports'],	'track'],
          ['Volleyball',	['boys_sports', 'girls_sports'],	'volleyball'],
          ['Wrestling',	['boys_sports', 'girls_sports'],	'wrestling'],
        ],
      },
    ]
    
end
