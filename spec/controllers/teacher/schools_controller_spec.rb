require 'rails_helper'

RSpec.describe Teacher::SchoolsController, type: :controller do
  let(:teacher) { create(:teacher) }
  let(:school) { create(:school) }
  let(:valid_attributes) { attributes_for(:school) }

  describe 'GET #new' do
    context 'as a guest' do
      it 'redirects' do
        get :new
        expect(response).to have_http_status(302)
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'is a success' do
          get :new
          expect(response).to have_http_status(200)
        end
      end

      context 'accepted in a school' do
        it 'redirects' do
          create(:school_teacher, teacher: teacher, approved: true)
          get :new
          expect(response).to have_http_status(302)
        end
      end

      context 'not accepted in a school' do
        it 'redirects' do
          create(:school_teacher, teacher: teacher, approved: false)
          get :new
          expect(response).to have_http_status(302)
        end
      end
    end
  end

  describe 'POST #create' do
    context 'as a guest' do
      it 'does not create a school' do
        expect {
          post :create, params: { school: valid_attributes }
        }.not_to change(School, :count)
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'creates a school' do
          expect {
            post :create, params: { school: valid_attributes }
          }.to change(School, :count).by(1)
        end

        it 'assigns the school to the teacher' do
          post :create, params: { school: valid_attributes }
          expect(teacher.reload.school_teacher).to be_truthy
        end

        it 'creates an unapproved SchoolUser' do
          post :create, params: { school: valid_attributes }
          expect(SchoolTeacher.last.approved).to be_falsy
        end

        it 'creates an new SchoolUser associated with the current user' do
          post :create, params: { school: valid_attributes }
          expect(SchoolTeacher.last.teacher).to eq(teacher)
        end

        it 're renders the page with invalid data' do
          post :create, params: { school: { invalid: 'attributes' } }
          expect(response).to have_http_status(200)
        end
      end

      context 'accepted in a school' do
        it 'does not create a school' do
          create(:school_teacher, teacher: teacher, approved: true)
          expect {
            post :create, params: { school: valid_attributes }
          }.not_to change(School, :count)
        end
      end

      context 'not accepted in a school' do
        it 'does not create a school' do
          create(:school_teacher, teacher: teacher, approved: false)
          expect {
            post :create, params: { school: valid_attributes }
          }.not_to change(School, :count)
        end
      end
    end
  end

  describe 'GET #show' do
    context 'as a guest' do
      it 'redirects' do
        get :show, params: { id: school.id }
        expect(response).to have_http_status(302)
      end
    end

    context 'as a teacher' do
      before(:each) { sign_in teacher.account }

      context 'without a school' do
        it 'redirects' do
          get :show, params: { id: school.id }
          expect(response).to have_http_status(302)
        end
      end

      context 'unapproved in that school' do
        it 'is a success' do
          SchoolTeacher.create(school: school, teacher: teacher, approved: false)
          get :show, params: { id: school.id }
          expect(response).to have_http_status(200)
        end
      end

      context 'approved in that school' do
        it 'is a success' do
          SchoolTeacher.create(school: school, teacher: teacher, approved: true)
          get :show, params: { id: school.id }
          expect(response).to have_http_status(200)
        end
      end

      context 'unapproved in another school' do
        it 'redirects' do
          create(:school_teacher, teacher: teacher, approved: false)
          get :show, params: { id: school.id }
          expect(response).to have_http_status(302)
        end
      end

      context 'approved in another school' do
        it 'redirects' do
          create(:school_teacher, teacher: teacher, approved: true)
          get :show, params: { id: school.id }
          expect(response).to have_http_status(302)
        end
      end
    end
  end
end
