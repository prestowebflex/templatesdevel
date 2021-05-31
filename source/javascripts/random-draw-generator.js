'use strict';

(function () {

	this.initMessagingApp = function (view, node) {
		var p = jQuery.Deferred(),
			renderDeferred = jQuery.Deferred();
		view.on("render", function () {
			renderDeferred.resolve();
		});
		if (window.App) {
			App.init(p, view, node, renderDeferred);
		} else {
			jQuery.ajax({
				url: node.collection.get('site').get('cable_js_url'),
				dataType: 'script',
				cache: true
			}).done(function (script, textStatus) {
				App.init(p, view, node, renderDeferred);
			}).fail(function (jqhxr, settings, exception) {
				// FIXME update these errors etc...
				p.reject('Failed to fetch ActionCable script');
			});
		}
		return p.promise();
	};

	var showConfirm = function showConfirm(message, confirmCallback, title, buttonLabels) {
		var _ref, _ref1;
		if (((_ref = window.navigator) != null ? (_ref1 = _ref.notification) != null ? _ref1.confirm : void 0 : void 0) != null) {
			window.navigator.notification.confirm(message, confirmCallback, title, buttonLabels);
		} else {
			confirmCallback.call(this, confirm(message) ? 1 : 2);
		}
	},
		_superClass = Backbone.Model.prototype,
		_syncMethodForModels = {
			sync: function sync() {
				return Backbone.ajaxSync.apply(this, arguments);
			}
		},
		AbstractModel = Backbone.Model.extend(_syncMethodForModels).extend({
			destroy: function destroy(options) {
				options = options || {};
				if (this.collection) {
					options.contentType = 'application/json';
					options.data = JSON.stringify({ client_guid: this.collection && this.collection.client_guid });
				}
				// super call
				return Backbone.Model.prototype.destroy.call(this, options);
			}
		}),
		AbstractCollection = Backbone.Collection.extend(_syncMethodForModels),

		// a user model to demo with
		User = Backbone.Model.extend({
		}),
		RandomCode = AbstractModel.extend({
			defaults: {
				client_guid: "",
				message: {
					message_category_id: "",
					parent_id: null,
					push_notifiation: false,
					message_view_permission: [],
					message_reply_permission: [],
					message_reply_view_permission: [],
					valid_from: null,
					valid_to: null,
					message: {},
					attachment_ids: []
				},
				drawnNumbers: [],
				member_id: null,
				membership_number: null
			},
			initialize: function initialize(attributes, options) {
				options = options || {};
			}
		}),
		ConfigModel = AbstractModel.extend({
			defaults: {
				isListView: false,
				random_draw_label: 'Draw Number',
				is_draw_enable: true
			},
			initialize: function initialize(attributes, options) {
				options = options || {};
			}
		}),
		RandomCodes = AbstractCollection.extend({
			model: RandomCode,
			getuuid: function getuuid() {
				// simple proxy onto the node
				return this.node.collection.getuuid();
			},
			initialize: function initialize(models, options) {
				options = options || {};
				this.node = options.node;
				this.client_guid = lib.utils.guid();
				//this.on('change:updated_at', this.sort, this);
			},
			url: function url() {
				return this.node.collection.url() + '/node/' + this.node.get('_id') + '/messages';
			}
		}),
		MemberList = AbstractModel.extend({
			defaults: {
				id: null,
				first_name: '',
				last_name: '',
				username: '',
				membership_number: null
			}
		}),
		MemberLists = AbstractCollection.extend({
			model: MemberList,
			initialize: function initialize(models, options) {
				options = options || {};
				this.node = options.node;
				this.client_guid = lib.utils.guid();
			},
			url: function url() {
				return this.node.collection.url() + '/node/' + this.node.get('_id') + '/random_generators';
			},
			sync: function (method, model, options) {
				var content = this.node.get('content');
				options = options || {};

				options.beforeSend = function (xhr) {
					var uuid = yourapp.getuuid();
      				var access_token = localStorage.getItem('access_token');
					if (access_token) {
						xhr.setRequestHeader('Authorization', "Bearer " + access_token);
					}
					xhr.setRequestHeader('X-Client-UUID', uuid);
				};
				var groups = _.without(content.app_groups, '');
				// groups = (content.type == 'appuser') ? groups : [];
				var value = (content.type == 'appuser') ? content.user_filter : ((content.type == 'viewpage') ? 'Node' : 'Coupon');

				var viewpage = _.without(content.page, '');
				var claimed_coupon = _.without(content.coupon_id, '');
				var resource_ids = (content.type == 'viewpage') ? viewpage : ((content.type == 'claimed_coupon') ? claimed_coupon : []);
				var formpage = content.formpage;
				var checkinpage = content.checkinpage;
				console.log('formpage', formpage)

				if (content.type == 'in_app_group') {
					var value = 'Group';
					var resource_ids = groups
				}
				if (content.type == 'won_a_coupon') {
					var value = 'Coupon';
					var resource_ids = claimed_coupon
				}
				if (content.type == 'form_data') {
					//var value = 'Coupon';
					var resource_ids = formpage
				}

				if (content.type == 'check_in_data') {
					//var value = 'Coupon';
					var resource_ids = checkinpage
				}
				options = _.extend({
					data: {
						"random_generator_filters": {
							"key": content.type,
							"value": value,
							"groups": groups,
							"resource_ids": resource_ids,
							"start_date": content.start_date,
							"end_date": content.end_date
						}
					}
				}, options);
				this.xhr = Backbone.sync.call(this, method, model, options);
				return this.xhr;
			}
		}),
		AbstractView = Backbone.View.extend({
			getNode: function getNode() {
				return this.options.node;
			},
			getMessageCategories: function getMessageCategories() {
				return _.map(this.getNode().get('message_categories'), message_categories => message_categories.id)
			},
			getMessageViewPermission: function getMessageViewPermission() {
				return _.map(this.getNode().get('message_view_permission'), message_view_permission => message_view_permission.id)
			},
			getMessageReplyPermission: function getMessageReplyPermission() {
				return _.map(this.getNode().get('message_reply_permission'), message_reply_permission => message_reply_permission.id)
			},
			getMessageReplyViewPermission: function getMessageReplyViewPermission() {
				return _.map(this.getNode().get('message_reply_view_permission'), message_reply_view_permission => message_reply_view_permission.id)
			},
			isAdmin: function isAdmin() {
				var user = this.node.collection.get('user');
				var res = [];
				if (user) {
					var admin_app_groups = this.node.get('content').admin_app_groups;
					var currentUserAppGroup = user.get('app_groups');
					res = currentUserAppGroup.filter((item1) =>
						!admin_app_groups.some((item2) => (item2 === item1.id))
					)
				}
				return (res.length > 0) ? true : false;
			},
			addNodeData: function (member_id, member_name, action) {
				var content = this.node.get('content')
				var values = {
					member_id: member_id,
					member_name: member_name,
					key: content.type,
					action: action,
					notes: content.notes
				}
				this.node.create(values);
			},
			getTodaydate: function () {
				var today = new Date(),
					timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone,
					options = { timeZone: timeZone },
					dateCheck = today.toLocaleDateString('en-AU', options),
					c = dateCheck.split("/");
				return new Date(c[2], parseInt(c[1]) - 1, c[0]);

			},
			validateDate: function () {
				var content = this.node.get('content'),
					draw_start_date = content.draw_start_date,
					draw_end_date = content.draw_end_date,
					d1 = draw_start_date.split("-"),
					d2 = draw_end_date.split("-"),
					from = new Date(d1[0], parseInt(d1[1]) - 1, d1[2], 0, 0, 0),
					to = new Date(d2[0], parseInt(d2[1]) - 1, d2[2], 23, 59, 59),
					check = this.getTodaydate(),
					validDate = false;

				if (draw_start_date && draw_end_date) {
					validDate = check >= from && check <= to;
				} else {
					validDate = check >= from;
				}
				return validDate;

			},
			getOldRendomDraw: function (oldRecord) {
				var content = this.node.get('content'),
					draw_start_date = content.draw_start_date,
					draw_end_date = content.draw_end_date,
					d1 = draw_start_date.split("-"),
					d2 = draw_end_date.split("-"),
					from = new Date(d1[0], parseInt(d1[1]) - 1, d1[2], 0, 0, 0),
					to = new Date(d2[0], parseInt(d2[1]) - 1, d2[2], 23, 59, 59);

				oldRecord = oldRecord.filter(function (item) {
					return new Date(item.created_at) >= from && new Date(item.created_at) <= to;
				});
				return oldRecord;
			},
			checkDrawLimit: function (oldRecord) {
				var content = this.node.get('content'),
					draw_start_date = content.draw_start_date,
					number_of_draw = content.number_of_draw,
					oldRecord = this.getOldRendomDraw(oldRecord),
					oldRecordCount = oldRecord.length,
					validDate = this.validateDate();
				if (validDate && oldRecordCount <= number_of_draw) {
					return true;
				} else {
					this.configmodel.set('random_draw_label', 'Next Draw ' + draw_start_date)
					this.configmodel.set('is_draw_enable', false)
					this.resetdraw('Reset Expired Code');

					return false;
				}
			},
			checkUsedMemberId: function (oldRecord, member_id) {
				oldRecord = this.getOldRendomDraw(oldRecord);
				oldRecord = oldRecord.filter((item) =>
					item.message.member_id == member_id
				);
				return (oldRecord.length) ? true : false;
			},
			getDrawMemberData: function (oldRecord, memberList) {
				oldRecord = this.getOldRendomDraw(oldRecord);
				var res = memberList.filter((item1) =>
					!oldRecord.some((item2) => (item2.message.member_id === item1.id))
				)
				return res;
			},
			endUserToggleList: function () {
				var content = this.node.get('content'),
					show_toggle_enduser = content.show_toggle_enduser;
				return (show_toggle_enduser == 1) ? true : false;
			},
			remove: function remove() {
				AbstractView.__super__.remove.apply(this, arguments);
				//this.trigger('remove', this);
				return this;
			},
			_destroyCancelConfirmation: function _destroyCancelConfirmation(message, callbackIfOk) {
				showConfirm(message, _.bind(function (result) {
					if (result == 1) {
						callbackIfOk.call(this);
					};
				}, this), 'Confirm', ['Yes', 'No']);
			},
			timeConvertor: function (time) {
				var PM = time.match('pm') ? true : false
				time = time.split(':')
				var min = time[1]
				if (PM) {
					var hour = 12 + parseInt(time[0], 10)
					min = min.replace('pm', '')
				} else {
					if (time[0] == '12') {
						var hour = 0;
					} else {
						var hour = time[0]
					}

					min = min.replace('am', '')
				}
				return hour + ':' + min;
			},
			getWeekDates: function (days) {
				var dates = [],
					date = this.getTodaydate(),
					year = date.getFullYear();
				console.log('year', year)
			},
			getMinutes: function (str) {
				var time = str.split(':');
				return time[0] * 60 + time[1] * 1;
			},
			getMinutesNow: function () {
				var timeNow = new Date();
				return timeNow.getHours() * 60 + timeNow.getMinutes();
			},
			currentTimeIsBetweenFromToTime: function (time_from, time_to) {
				var now = this.getMinutesNow();
				var start = this.getMinutes(time_from);
				var end = this.getMinutes(time_to);
				if (start > end) end += getMinutes('24:00');
				return (now > start) && (now < end)
			},
			checkWeekDatesWithCurrentDate: function (days, date, allday, time_from, time_to) {
				//var dates = this.getWeekDates(days);
				var status = false;
				var current_day = date.getDay();
				if (allday == 1) {
					days = ["0", "1", "2", "3", "4", "5", "6"];
				}
				if (_.indexOf(days, current_day.toString()) != -1) {
					status = true
				} else {
					return false;
				}
				if (allday == 1) {
					status = true;
				}
				console.log('status before time', status)
				if (time_from && time_to) {
					time_from = this.timeConvertor(time_from);
					time_to = this.timeConvertor(time_to);
					status = this.currentTimeIsBetweenFromToTime(time_from, time_to);
				}
				return status;
			},
			getMonthDates: function (month_dates, date, allday, time_from, time_to, int = '') {

				if (allday == 1) {
					var day = [];
					for (var x = 1; x <= 31; x++) {
						day.push(x);
					}
					month_dates = day;
				}

				var current_date = date.getDate();
				var status = false;
				if (int == 'int') {
					var index = _.indexOf(month_dates, current_date);
				} else {
					var index = _.indexOf(month_dates, current_date.toString());
				}
				if (index != -1) {
					status = true;
				} else {
					return false;
				}
				if (time_from && time_to) {
					time_from = this.timeConvertor(time_from);
					time_to = this.timeConvertor(time_to);
					status = this.currentTimeIsBetweenFromToTime(time_from, time_to);
				}
				return status;
			},
			findNextDrawDate: function (days, date, time_from, allday) {
				var current_day = date.getDay();
				if (allday == 1) {
					days = ["0", "1", "2", "3", "4", "5", "6"];
				}
				var index = _.indexOf(days, current_day.toString());
				var index2 = 0;
				var next_index = 0;
				if (index == -1) {
					var is_next_date = false;
					_.each(days, function (day, index1) {
						var is_next_date = false;
						if (day > current_day && !is_next_date) {
							index2 = day;
							is_next_date = true

						}
					})
				}

				if (index == -1) {
					if (index2) {
						next_index = Number(index2) - Number(current_day);
					} else {
						next_index = (7 - Number(current_day)) + Number(days[0]);
						console.log('next_index sss', next_index)
					}

				} else if (index && days[index + 1]) {
					//next_index = days[index+1];
					next_index = 1;
				} else {
					next_index = days[0];
				}
				var next_date = date;

				var now = this.getMinutesNow();
				var time_from1 = this.timeConvertor(time_from);
				var start = this.getMinutes(time_from1);
				if (now < start && allday == 1) {
					next_index = 0;
				}
				if (now < start && index > 0) {
					next_index = 0;
				}
				next_date.setDate(new Date().getDate() + Number(next_index))
				var timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone,
					options = { timeZone: timeZone },
					next_date = next_date.toLocaleDateString('en-AU', options);
				this.configmodel.set('random_draw_label', 'Next Draw ' + next_date + ' ' + time_from)
				this.configmodel.set('is_draw_enable', false)

				this.resetdraw('Reset Expired Code');

			},
			findNextMonthlyDayDrawDate: function (month_dates, date, time_from, allday, int = '') {
				var current_date = date.getDate();
				if (allday == 1) {
					var day = [];
					for (var x = 1; x <= 31; x++) {
						day.push(x);
					}
					month_dates = day;
				}
				if (int == 'int') {
					var index = _.indexOf(month_dates, current_date);
				} else {
					var index = _.indexOf(month_dates, current_date.toString());
				}
				var index2 = 0;
				var next_index = 0;
				var total_day_month = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();

				if (index == -1) {
					var is_next_date = false;
					_.each(month_dates, function (day, index1) {
						if (day > current_date && !is_next_date) {
							index2 = day;
							is_next_date = true;
							return true;
						}
					})
				}
				if (index == -1) {
					if (index2) {
						next_index = Number(index2) - Number(current_date);
					} else {
						if (month_dates[0] == -2) {
							next_index = (total_day_month - 1) - Number(current_date)
						} else if (month_dates[0] == -1) {
							next_index = total_day_month - Number(current_date)
						} else {
							next_index = (total_day_month - Number(current_date)) + Number(month_dates[0]);
						}
					}

				} else if (index && month_dates[index + 1]) {
					//next_index = days[index+1];
					next_index = 1;
				} else {
					next_index = month_dates[0];
				}
				var next_date = date;

				var now = this.getMinutesNow();
				var time_from1 = this.timeConvertor(time_from);
				var start = this.getMinutes(time_from1);
				if (now < start && allday == 1) {
					next_index = 0;
				}
				if (now < start && index > 0) {
					next_index = 0;
				}
				next_date.setDate(new Date().getDate() + Number(next_index))
				var timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone,
					options = { timeZone: timeZone },
					next_date = next_date.toLocaleDateString('en-AU', options);
				this.configmodel.set('random_draw_label', 'Next Draw ' + next_date + ' ' + time_from)
				this.configmodel.set('is_draw_enable', false)

				this.resetdraw('Reset Expired Code');

			},
			UpdateGetWeeksInMonth: function (year, month) {
				const weeks = [],
					firstDate = new Date(year, month, 1),
					lastDate = new Date(year, month + 1, 0),
					numDays = lastDate.getDate();

				let dayOfWeekCounter = firstDate.getDay();

				for (let date = 1; date <= numDays; date++) {
					if (dayOfWeekCounter === 0 || weeks.length === 0) {
						weeks.push([]);
					}
					weeks[weeks.length - 1][dayOfWeekCounter] = date;
					dayOfWeekCounter = (dayOfWeekCounter + 1) % 7;
				}
				var a_weeks = [];
				weeks
					.filter((w) => !!w.length)
					.map((w) => w);
				var su = [], mo = [], tu = [],
					we = [], th = [], fr = [], sa = [];
				for (let day = 0; day < weeks.length; day++) {
					if (weeks[day][0]) {
						su.push(weeks[day][0])
					}
					if (weeks[day][1]) {
						mo.push(weeks[day][1])
					}
					if (weeks[day][2]) {
						tu.push(weeks[day][2])
					}
					if (weeks[day][3]) {
						we.push(weeks[day][3])
					}
					if (weeks[day][4]) {
						th.push(weeks[day][4])
					}
					if (weeks[day][5]) {
						fr.push(weeks[day][5])
					}
					if (weeks[day][6]) {
						sa.push(weeks[day][6])
					}
				}
				a_weeks.push(su)
				a_weeks.push(mo)
				a_weeks.push(tu)
				a_weeks.push(we)
				a_weeks.push(th)
				a_weeks.push(fr)
				a_weeks.push(sa)
				return a_weeks;
			},
			getNthDayOfMonth: function (index, day, month, year) {
				// Create date object
				var date = new Date();
				// Set to first day of month
				date.setDate(1);
				// If supplied – set the month
				if (month !== '' && month !== undefined) {
					// Set month
					date.setMonth(month);
				} else {
					month = date.getMonth();
				}
				// If supplied – set the year
				if (year != '' && year !== undefined) {
					// Set year
					date.setFullYear(year);
				} else {
					year = date.getFullYear();
				}
				// Find daynumber
				var firstDay = date.getDay();
				// Find first friday.
				while (date.getDay() != day) {
					date.setDate(date.getDate() + 1);
				}
				switch (index) {
					case 2:
						date.setDate(date.getDate() + 7);
						break;
					case 3:
						date.setDate(date.getDate() + 14);
						break;
					case 4:
						date.setDate(date.getDate() + 21);
						break;
					case 5:
						date.setDate(date.getDate() + 28);
						if (date.getMonth() !== month) {
							date = null;
						}
						break;
				}
				return date;
			},
			getMonthlyDay: function (month_days, date, allday, time_from, time_to) {
				var year = date.getFullYear(),
					month = date.getMonth(),
					u_weeks = this.UpdateGetWeeksInMonth(year, month),
					status = false,
					self = this,
					month_dates = [];
				_.each(month_days, function (week_day, index) {
					var week_day_array = week_day.split(',')
					var day = week_day_array[0];
					var week_number = week_day_array[1];
					var currentday = u_weeks[day]
					var o_week_number = (week_number == '-1') ? (currentday.length - 1) : (week_number - 1);
					var currentdate = currentday[o_week_number];
					// week_number = (week_number == '-1') ? (weeks.length - 1) : (week_number - 1);
					var nth_date = self.getNthDayOfMonth(o_week_number, day);
					//month_dates.push(nth_date.getDate())
					month_dates.push(currentdate)
				})
				month_dates.sort(function (a, b) { return a - b });
				status = this.getMonthDates(month_dates.toString(), date, allday, time_from, time_to, 'int')
				if (!status) {
					this.findNextMonthlyDayDrawDate(month_dates, date, time_from, allday, 'int')
				}
				return status;
			},
			checkDrawDate: function () {
				var content = this.node.get('content'),
					type_of_days = content.type_of_days,
					allday = content.allday,
					week_days = _.without(content.week_days, ''),
					month_dates = _.without(content.month_dates, ''),
					month_days = _.without(content.month_days, ''),
					everyday = _.without(content.everyday, ''),
					time_from = content.time_from,
					time_to = content.time_to,
					status = true,
					date = this.getTodaydate();
				switch (type_of_days) {
					case "weekly":
						console.log('Weekly')
						if (week_days.length > 0) {
							status = this.checkWeekDatesWithCurrentDate(week_days, date, allday, time_from, time_to);
							if (!status) {
								this.findNextDrawDate(week_days, date, time_from, allday)
							}
						}
						break;
					case "monthly_day":
						console.log('monthly_day')
						if (month_dates.length > 0) {
							status = this.getMonthDates(month_dates, date, allday, time_from, time_to);
							if (!status) {
								this.findNextMonthlyDayDrawDate(month_dates, date, time_from, allday)
							}
						}
						break;
					case "monthly":
						console.log('monthly')
						if (month_days.length > 0) {
							status = this.getMonthlyDay(month_days, date, allday, time_from, time_to);
						}
						break;
					case "everyday":
						console.log('everyday')
						if (everyday.length > 0) {
							status = this.checkWeekDatesWithCurrentDate(everyday, date, allday, time_from, time_to);
							if (!status) {
								this.findNextDrawDate(everyday, date, time_from, allday)
							}
						}
						break;
					default:
						status = true;
				}
				if (status) {
					this.configmodel.set('random_draw_label', 'Draw Number')
					this.configmodel.set('is_draw_enable', true)
				}
				return status;
			}
		}),
		AppView = AbstractView.extend({
			_connected: false,
			initialize: function initialize(options) {
				options = options || {};

				if (options.app) {
					// setup websockets
					this.app = options.app;
					this.node = options.node;
					this.memberlist = options.memberlist;
					this.configmodel = options.configmodel
					// bind message  updates to the main model!
					// just send them into the main model
					//console.log('this.app', this.app)
					this.listenTo(this.app, 'received', this.onReceived);
					this.listenTo(this.app, 'connected', this.onConnect);
					this.listenTo(this.app, 'disconnected', this.onDisconnect);
					this.listenTo(this.model, 'sync', this.randomcodeSynced);
					this.app.init(true); // force start
				}
				// this is just called once to setup the view for the application only
				// setup timer
				// bind a timer to appView
				this.on("stoptimer", this.clearTock, this);
				$.mobile.showPageLoadingMsg("a", "Connecting");
			},
			onDisconnect: function onDisconnect() {
				this._connected = false;
				$.mobile.showPageLoadingMsg("a", "Reconnecting");
			},
			onConnect: function onConnect() {
				this._connected = true;
				$.mobile.showPageLoadingMsg("a", "Updating randomcode");
				var self = this;
				this.model.fetch({
					success: function (collection, response, options) {
						self.checkDrawDate();
						var oldRecord = self.model.toJSON();
						var drawlimit = self.checkDrawLimit(oldRecord);
						self.render();
						var validateDate = self.validateDate();
						if (!validateDate) {
							setTimeout(function () {
								self.resetdraw('Reset Expired Code');
							}, 100);
						}
					}
				});
				this.memberlist.fetch();
			},
			randomcodeSynced: function randomcodeSynced() {
				$.mobile.hidePageLoadingMsg();
			},
			all: function all() {
				console.log("SOCKET ALL", arguments);
			},
			onReceived: function onReceived(message) {
				var type = message.type,
					data = message.data;
				if (type == 'message_delete') {
					this.model.remove(data.id);
				} else {
					this.model.add(data, { parse: true, merge: true });
				}
				this.render();
				$.mobile.hidePageLoadingMsg();
			},
			render: function () {
				var lastDrawModel = _.last(this.model.models);
				var lastDrawData = (lastDrawModel) ? lastDrawModel.toJSON() : '';
				var random_draw_label = this.configmodel.get('random_draw_label');
				var drawNumber = (_.isObject(lastDrawData)) ? lastDrawData.message.message : random_draw_label;
				var btnDisabled = (_.isObject(lastDrawData) && lastDrawData.message.message) ? '' : 'disabled';

				var html = '<div id="raffleNumber">';
				if (!this.configmodel.get('isListView')) {
					html += drawNumber;
				} else {
					var newRowAt = 6;
					var rowCount = 0;
					this.model.models.forEach(function (model) {
						var modelData = model.toJSON();
						if (rowCount === 0 || rowCount % newRowAt === 0) {
							html += '<div class="left">';
						}
						html += '<div class="drawnNumber" id="num_' + rowCount + '" >' + modelData.message.message;
						html += '</div>';
						if ((rowCount + 1) % newRowAt == 0) {
							html += '</div>';
						}
						rowCount++;
					})
					html += '</div>';
				}
				html += '</div>';
				if (this.isAdmin()) {
					html += '<div id="adminControls">';
					html += '<div id="buttonReset" class="adminControlsButton"><button id="resetButton" ' + btnDisabled + ' type="button">Reset</button></div>';
					html += '<div id="buttonUndo" class="adminControlsButton"><button ' + btnDisabled + ' id="undoButton" type="button">Undo</button></div>';
					html += '<div id="buttonToggleList" class="adminControlsButton"><button id="toggleListButton" type="button">Toggle List</button></div>';
					html += '<div id="bottomAdminButtons" class="adminControlsButton"><div id="buttonGenerate"><button id="generateButton" type="button">Generate</button></div></div>';
					html += '</div>';
				} else {
					if (this.endUserToggleList()) {
						html += '<div id="adminControls" class="endUserAdminControls">';
						html += '<div id="buttonToggleList" class="adminControlsButton"><button id="toggleListButton" type="button">Toggle List</button></div>';
						html += '</div>';
					}
				}
				this.$el.html(html);
				return this;
			},
			events: {
				'click #generateButton': 'generateNumbers',
				'click #resetButton': 'resetPage',
				'click #undoButton': 'undoLastValue',
				'click #toggleListButton': 'toggleListButton'
			},
			capitalize: function (string) {
				return string.charAt(0).toUpperCase() + string.substring(1).toLowerCase();
			},
			resetPage: function (e) {
				e.preventDefault();
				this._destroyCancelConfirmation('Really reset this?', function () {
					$.mobile.showPageLoadingMsg("a", "Processing..");
					this.resetdraw('Reset Generated Code');
				});
			},
			resetdraw: function (restMessage) {
				var $this = this;
				var collection = this.model;
				_.each(collection.models, function (model) {
					console.log('Reset Expired model', model)
					setTimeout(function () {
						model.destroy({
							success: function () {
								console.log('success');
								var modelData = model.toJSON();
								$this.addNodeData(modelData.message.membership_number, modelData.message.member_name, restMessage)
							},
							error: function () {
								console.log('error');
							}
						});
					}, 100)
				})
			},
			undoLastValue: function (e) {
				this._destroyCancelConfirmation('Really want to undo?', function () {
					var lastMessageModel = _.last(this.model.models);
					var modelData = lastMessageModel.toJSON();
					var $self = this;
					lastMessageModel.destroy({
						success: function () {
							console.log('success');
							$self.addNodeData(modelData.message.membership_number, modelData.message.member_name, 'undo Generated Code')
						},
						error: function () {
							console.log('You are access to undo last value');
						}
					})
				});
			},
			toggleListButton: function () {
				console.log('toggel list')
				var isListView = this.configmodel.get('isListView')
				this.configmodel.set('isListView', (isListView) ? false : true);
				this.render()
			},
			generateNumbers: function () {

				var member_list = this.memberlist.toJSON();
				var oldRecord = this.model.toJSON();
				var drawlimit = this.checkDrawLimit(oldRecord);
				var drawList = this.getDrawMemberData(oldRecord, member_list);
				var newNumber = this.getRandomInt(drawList);
				var is_draw_enable = this.configmodel.get('is_draw_enable');
				if (!is_draw_enable) {
					alert('Draw is not available today')
				} else if (!drawlimit) {
					alert('Draw limit exceeded')
				} else {
					if (newNumber) {
						$.mobile.showPageLoadingMsg("a", "Added new Random Code");
						var member_name = this.capitalize(newNumber.first_name);
						if (newNumber.last_name) {
							member_name = member_name + ' ' + this.capitalize(newNumber.last_name);
						}
						var random_number = member_name + '(' + newNumber.membership_number + ')';
						var self = this;
						this.model.create({
							client_guid: this.collection && this.collection.client_guid,
							message: {
								message_category_id: this.getMessageCategories(),
								message_view_permission: this.getMessageViewPermission(),
								message_reply_permission: this.getMessageReplyPermission(),
								message_reply_view_permission: this.getMessageReplyViewPermission(),
								message: {
									title: random_number,
									message: random_number,
									member_id: newNumber.id,
									member_name: member_name,
									membership_number: newNumber.membership_number,
								}
							}
						}, {
							success: function () {
								self.addNodeData(newNumber.membership_number, member_name, 'New Code Generated')
							},
							error: function (model, response) {
								console.log('Error response', response)
							}
						});
					} else {
						if (this.memberlist.models.length > 0) {
							alert('Draw Completed')
						} else {
							alert('No member record found.')
						}
					}
				}
			},
			getRandomInt: function (member_list) {
				return member_list[Math.floor(Math.random() * member_list.length)];
			}
		}); //end var

	// APP INIT
	// initApp2(view, node).done(

	this.getStartMessagingAppFunction = function (view, node) {
		// need to pass in view and node to get this working.
		return function (actionCableApp) {
			var configmodel = new ConfigModel({ isListView: false });
			var memberList = new MemberLists([], { node: node });
			var randomcode = new RandomCodes([], { node: node }),
				app = new AppView({
					model: randomcode,
					memberlist: memberList,
					configmodel: configmodel,
					node: node,
					app: actionCableApp,
					el: view.$('.raffle_template')[0]
				}).render();


			view.on('closepage', function () {
				app.trigger("stoptimer");
			});

			window.view = view;
			window.app = app;
			window.randomcode = randomcode;
			// });
		};
	};

	this.RandomCode = RandomCode;
}).call(window);
