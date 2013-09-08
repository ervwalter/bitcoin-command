/*  https://github.com/florianorben/angular-interval/  */

angular.module('interval', []).provider('$interval', function $intervalProvider() {
    'use strict';

    var jobs = {},
        providerSelf = this;

    /**
     * automatically call synchronize method once a job is added
     * @type {Boolean} default = false
     */
    this.autoSync = false;

    this.$get = ['$exceptionHandler', '$rootScope', function $interval($exceptionHandler, $rootScope) {

        /**
         * adds a new job to execute on given interval
         * @param {Function} fn            Function to execute
         * @param {Number}   [delay=0]         Re-Execute after X milliseconds
         * @param {Number}   [maxExecutions=0] Maximum number of executions, 0 equals unlimited executions
         * @param {Boolean}   [invokeApply=true]   Trigger scope.$apply
         * @return {Job} Job
         */
        function Job (fn, delay, maxExecutions, invokeApply) {
            var id,
                skipApply = (angular.isDefined(invokeApply) && !invokeApply),
                self = this,
                callbacks = [],
                errCallbacks = [],
                executions = 0,
                added = new Date().getTime(),
                firstExecution = undefined,
                nextExecution = undefined,
                lastExecution = undefined,
                status = '';

            /**
             * start job
             * @chainable
             * @return {self}
             */
            self.start = function() {
                if (jobs[id] && angular.isDefined(this.info().nextExecution)) return self;
                if (jobs[id] && angular.isUndefined(this.info().nextExecution)) delete jobs[id];

                // status = 'STARTED';

                id = setInterval(function() {
                    var i = 0,
                        j = 0;

                    if (!firstExecution) {
                        firstExecution = new Date().getTime();
                    }
                    if (!nextExecution) {
                        nextExecution = new Date().getTime();
                    }

                    if (maxExecutions) {
                        lastExecution = nextExecution + (maxExecutions - executions) * delay;
                    }

                    try {
                        var returnValue = fn();
                        for (i; i < callbacks.length; i++) {
                            callbacks[i].call(null, returnValue);
                        }
                    } catch (e) {
                        for (j; j < callbacks.length; j++) {
                            try {
                                errCallbacks[j].call(null, e);
                            } catch (e2) {
                                $exceptionHandler(e2);
                            }
                        }
                        $exceptionHandler(e);
                    }
                    executions++;

                    nextExecution = nextExecution + delay;

                    if (maxExecutions > 0 && maxExecutions === executions) {
                        self.cancel();
                    }

                    if (!skipApply) $rootScope.$apply();
                }, delay);
                jobs[id] = self;
                return self;
            };
            /**
             * pause job for X milliseconds
             * @param  {Number} pauseTime pause for x milliseconds
             * @param {Function} callback function to be called, once interval resumes
             * @chainable
             * @return {self}
             */
            self.pause = function(pauseTime, callback) {
                nextExecution = undefined;
                clearInterval(id);
                // status = 'PAUSED';
                // $rootScope.$apply();
                setTimeout(function() {
                    self.start();
                    if (angular.isFunction(callback)) {
                        callback();
                    }
                }, pauseTime);
                return self;
            };

            /**
             * stop job
             * @chainable
             * @return {self}
             */
            self.stop = function() {
                // status = 'STOPPED';
                // $rootScope.$apply();
                nextExecution = undefined;
                clearInterval(id);
                return self;
            };

            /**
             * cancel job
             * @chainable
             * @return {self}
             */
            self.cancel = function() {
                // status = 'CANCELLED';
                // $rootScope.$apply();
                nextExecution = undefined;
                clearInterval(id);
                delete jobs[id];
                return null;
            };
            /**
             * add a callback to execute on each tick
             * @param  {Function} success Execute on successfull function call
             * @param  {Function} error   Execute on error
             * @chainable
             * @return {self}
             */
            self.then = function(success, error) {
                if (angular.isFunction(success)) {
                    callbacks.push(success);
                }
                if (angular.isFunction(error)) {
                    errCallbacks.push(error);
                }
            };
            /**
             * synchronize all jobs
             *
             * causes all jobs to stop and immediately start at the same time, regardless
             * of when they've been added
             *
             * @chainable
             * @return {self}
             */
            self.synchronize = function() {
                var temp = [];
                angular.forEach(jobs, function(j) {
                    temp.push(j);
                    j.stop();
                });
                angular.forEach(temp, function(t) {
                    t.start();
                });
                return self;
            };

            /**
             * return meta information about current job
             * @return {Object} information
             */
            self.info = function() {
                return {
                    added: added,
                    firstExecution: firstExecution,
                    nextExecution: nextExecution,
                    lastExecution: lastExecution,
                    status: status
                }
            };

            self.start();
        }


        function JobManager (fn, delay, maxExecutions,invokeApply) {
            var job = new Job(fn || function() {}, delay || 0,
                maxExecutions !== 0 && angular.isNumber(maxExecutions) && maxExecutions > 0 ? maxExecutions : 0,
                invokeApply);
            return providerSelf.autoSync ? job.synchronize() : job;
        }

        /**
         * return a list of all started, paused and stopped jobs
         * @return {Object} list of jobs
         */
        JobManager.getJobs = function () {
            return jobs;
        }

        return JobManager;
    }];
});