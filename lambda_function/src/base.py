import logging
import os
import sys
import traceback


class LambdaFunctionBase:
    """
    Base class used to implement Python Lambda.
    """

    def __init__(self):
        self.logger = logging.getLogger(self.__class__.__name__)
        self.logger.setLevel(os.environ.get('LOGLEVEL', logging.INFO))

    def _debug(self, event, context):
        """ Debug the outputs of the method. """
        self.logger.debug("Printing Lambda inputs:")
        self.logger.debug("> event: %s", (event if event is not None else 'None'))
        self.logger.debug("> context: %s", (context if context is not None else 'None'))
        for item, value in os.environ.items():
            if item.startswith('PARAM_SECRET_'):
                self.logger.debug('> env[%s]: %s', item, 'Is set')
            elif item.startswith('PARAM_'):
                self.logger.debug('> env[%s]: %s', item, value)

    def _build_response_ok(self, body=None):
        """ Returns a successful result. """
        return {
            'statusCode': 200,
            'body': body or ''
        }

    def _build_response_uncaught_exception(self):
        """ Handle uncatched exceptions. """
        exception_type, exception_value, exception_traceback = sys.exc_info()
        error_traces = traceback.format_exception(exception_type, exception_value, exception_traceback)
        error_message = '{} {}'.format(exception_type.__name__, str(exception_value))
        return {
            'statusCode': 500,
            'body': {
                'httpStatus': 500,
                'message': error_message,
                'trace': error_traces or []
            }
        }

    def _check_inputs(self, event):
        """ Check the inputs of the method. """

    def _execute(self, event, context):  # pylint: disable=W0613
        """ Execute the method. """
        return None

    def process_event(self, event, context):
        """ Function invoked by AWS. """
        try:
            # Trace inputs in DEBUG.
            self._debug(event, context)

            # Check inputs.
            self._check_inputs(event)

            # Build a response.
            return self._build_response_ok(self._execute(event, context))
        except Exception:  # pylint: disable=W0703
            error_message = self._build_response_uncaught_exception()
            self.logger.error(error_message['body'])
            return error_message
