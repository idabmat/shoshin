require 'rails_helper'

RSpec.describe Teacher::ClassroomsController, type: :controller do
  let(:school) { create(:school) }
  let!(:classroom) { create(:classroom, school: school) }
  let(:teacher) { create(:teacher) }
  let(:valid_attributes) {
    { name: Faker::Company.profession, level_id: create(:level).id }
  }

  describe 'GET #show' do
    context 'as a guest' do
      it 'should redirect' do
        get :show, params: { id: classroom.id }
        expect(response).to have_http_status(302)
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'should redirect' do
          get :show, params: { id: classroom.id }
          expect(response).to have_http_status(302)
        end
      end

      context 'from the same school as the classroom' do
        it 'should be a success' do
          school.update(teachers: [teacher])
          get :show, params: { id: classroom.id }
          expect(response).to have_http_status(200)
        end
      end

      context 'from another school' do
        it 'should redirect' do
          create(:school_teacher, teacher: teacher, approved: true)
          get :show, params: { id: classroom.id }
          expect(response).to have_http_status(302)
        end
      end
    end
  end

  describe 'GET #new' do
    context 'as a guest' do
      it 'redirects' do
        get :new, params: { school_id: school.id }
        expect(response).to have_http_status(302)
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'redirects' do
          get :new, params: { school_id: school.id }
          expect(response).to have_http_status(302)
        end
      end

      context 'from the school' do
        it 'is a success' do
          school.update(teachers: [teacher])
          get :new, params: { school_id: school.id }
          expect(response).to have_http_status(200)
        end
      end

      context 'from another school' do
        it 'redirects' do
          create(:school_teacher, teacher: teacher, approved: true)
          get :new, params: { school_id: school.id }
          expect(response).to have_http_status(302)
        end
      end
    end
  end

  describe 'POST #create' do
    context 'as a guest' do
      it 'does not create a classroom' do
        expect {
          post :create, params: { school_id: school.id,
                                  classroom: valid_attributes }
        }.not_to change(Classroom, :count)
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'does not create a classroom' do
          expect {
            post :create, params: { school_id: school.id,
                                    classroom: valid_attributes }
          }.not_to change(Classroom, :count)
        end
      end

      context 'not yet approved in the school' do
        it 'does not create a classroom' do
          school.update(pending_teachers: [teacher])
          expect {
            post :create, params: { school_id: school.id,
                                    classroom: valid_attributes }
          }.not_to change(Classroom, :count)
        end
      end

      context 'from the school' do
        before { school.update(teachers: [teacher]) }

        context 'with valid data' do
          it 'creates a classroom' do
            expect {
              post :create, params: { school_id: school.id,
                                      classroom: valid_attributes }
            }.to change(Classroom, :count).by(1)
          end

          it 'redirects' do
            post :create, params: { school_id: school.id,
                                    classroom: valid_attributes }
            expect(response).to have_http_status(302)
          end
        end

        context 'with invalid data' do
          it 'does not create the school with invalid data' do
            expect {
              post :create, params: { school_id: school.id,
                                      classroom: { invalid: 'attributes' } }
            }.not_to change(Classroom, :count)
          end

          it 're renders the page' do
            post :create, params: { school_id: school.id,
                                    classroom: { invalid: 'attributes' } }
            expect(response).to have_http_status(200)
          end
        end
      end

      context 'from another school' do
        it 'does not create a classroom' do
          create(:school_teacher, teacher: teacher, approved: true)
          expect {
            post :create, params: { school_id: school.id,
                                    classroom: valid_attributes }
          }.not_to change(Classroom, :count)
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'as a guest' do
      it 'should redirect' do
        get :edit, params: { id: classroom.id }
        expect(response).to have_http_status(302)
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'should redirect' do
          get :edit, params: { id: classroom.id }
          expect(response).to have_http_status(302)
        end
      end

      context 'from the same school as the classroom' do
        it 'should be a success' do
          school.update(teachers: [teacher])
          get :edit, params: { id: classroom.id }
          expect(response).to have_http_status(200)
        end
      end

      context 'from another school' do
        it 'should redirect' do
          create(:school_teacher, teacher: teacher, approved: true)
          get :edit, params: { id: classroom.id }
          expect(response).to have_http_status(302)
        end
      end
    end
  end

  describe 'PATCH #update' do
    context 'as a guest' do
      it 'does not update the school' do
        patch :update, params: { id: classroom.id, classroom: { name: 'foo' } }
        expect(classroom.reload.name).not_to eq('foo')
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'does not update the classroom' do
          patch :update, params: { id: classroom.id,
                                   classroom: { name: 'foo' } }
          expect(classroom.reload.name).not_to eq('foo')
        end
      end

      context 'not approved in the school' do
        it 'does not update the classroom' do
          create(:school_teacher, school: school, teacher: teacher,
                                  approved: false)
          patch :update, params: { id: classroom.id,
                                   classroom: { name: 'foo' } }
          expect(classroom.reload.name).not_to eq('foo')
        end
      end

      context 'approved in the school' do
        before :each do
          create(:school_teacher, school: school, teacher: teacher,
                                  approved: true)
        end

        context 'with valid data' do
          it 'updates the school' do
            patch :update, params: { id: classroom.id,
                                     classroom: { name: 'foo' } }
            expect(classroom.reload.name).to eq('foo')
          end

          it 'redirects' do
            patch :update, params: { id: classroom.id,
                                     classroom: { name: 'foo' } }
            expect(response).to have_http_status(302)
          end
        end

        context 'with invalid data' do
          it 'does not update the school' do
            patch :update, params: { id: classroom.id,
                                     classroom: { name: '' } }
            expect(classroom.reload.name).not_to eq('')
          end

          it 're renders the page' do
            patch :update, params: { id: classroom.id,
                                     classroom: { name: '' } }
            expect(response).to have_http_status(200)
          end
        end
      end

      context 'from another school' do
        it 'does not update the classroom' do
          create(:school_teacher, teacher: teacher, approved: true)
          patch :update, params: { id: classroom.id,
                                   classroom: { name: 'foo' } }
          expect(classroom.reload.name).not_to eq('foo')
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'as a guest' do
      it 'does not destroy the classroom' do
        expect {
          delete :destroy, params: { id: classroom.id }, format: :js
        }.not_to change(Classroom, :count)
      end
    end

    context 'as a teacher' do
      before { sign_in teacher.account }

      context 'approved in the school' do
        before { create(:school_teacher, teacher: teacher, school: school,
                                         approved: true) }
        it 'destroys the classroom with no students' do
          expect {
            delete :destroy, params: { id: classroom.id }, format: :js
          }.to change(Classroom, :count).by(-1)
        end

        it 'does not destroy the classroom with students' do
          create(:student, classroom: classroom)
          expect {
            delete :destroy, params: { id: classroom.id }, format: :js
          }.not_to change(Classroom, :count)
        end
      end

      context 'not approved in the school' do
        it 'does not destroy the school' do
          create(:school_teacher, teacher: teacher, school: school,
                                  approved: false)
          expect {
            delete :destroy, params: { id: classroom.id }, format: :js
          }.not_to change(Classroom, :count)
        end
      end

      context 'approved in another school' do
        it 'does not destroy the school' do
          create(:school_teacher, teacher: teacher, approved: true)
          expect {
            delete :destroy, params: { id: classroom.id }, format: :js
          }.not_to change(Classroom, :count)
        end
      end

      context 'without a school' do
        it 'does not destroy the school' do
          expect {
            delete :destroy, params: { id: classroom.id }, format: :js
          }.not_to change(Classroom, :count)
        end
      end
    end
  end
end
